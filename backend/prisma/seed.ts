import { PrismaClient } from '@prisma/client';
import 'dotenv/config';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
    console.log("🌱 Starting seed...");

    // إنشاء مدارس تجريبية
    const schoolsData = [
        { name: "Marj Al-Hamam", adminEmail: "admin@marj.edu.jo", code: "MARJ2024" },
        { name: "Irbid Secondary", adminEmail: "admin@irbid.edu.jo", code: "IRBID2024" },
        { name: "Amman Academy", adminEmail: "admin@amman.edu.jo", code: "AMMAN2024" },
    ];

    for (const data of schoolsData) {
        // 1. إنشاء المدرسة أو تحديثها
        const school = await prisma.school.upsert({
            where: { name: data.name },
            update: {
                adminEmail: data.adminEmail,
                teacherSecretCode: data.code,
            },
            create: {
                name: data.name,
                adminEmail: data.adminEmail,
                adminPassword: await bcrypt.hash("password123", 10),
                teacherSecretCode: data.code,
                isPasswordChanged: false,
            }
        });

        console.log(`✅ School ${school.name} is ready.`);

        // 2. إنشاء حساب المدير (User with role PRINCIPAL)
        const hashedPassword = await bcrypt.hash("password123", 10);
        await prisma.user.upsert({
            where: { email: data.adminEmail },
            update: {
                password: hashedPassword,
                role: 'PRINCIPAL',
                school: school.name,
                schoolId: school.id,
            },
            create: {
                nationalId: `ADMIN_${school.name.toUpperCase().replace(/\s/g, '_')}`,
                fullName: `${school.name} Principal`,
                username: `admin_${school.name.toLowerCase().replace(/\s/g, '_')}`,
                email: data.adminEmail,
                password: hashedPassword,
                role: 'PRINCIPAL',
                school: school.name,
                schoolId: school.id,
            }
        });

        console.log(`👤 Principal for ${school.name} created.`);
    }

    console.log("🏁 Seed finished successfully!");
}

main()
    .catch((e) => {
        console.error("❌ Seed failed:", e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });