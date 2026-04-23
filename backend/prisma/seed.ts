import { PrismaClient } from '@prisma/client';
import 'dotenv/config';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
    console.log("🌱 Starting seed...");

    // إنشاء مدارس لواء وادي السير
    const schoolsData = [
        { name: "وادي السير الثانوية للبنين", adminEmail: "admin@wadiseer-boy.edu.jo", code: "WADI2024" },
        { name: "مرج الحمام الثانوية للبنات", adminEmail: "admin@marj-girl.edu.jo", code: "MARJ2024" },
        { name: "أم عبهرة الثانوية", adminEmail: "admin@obhara.edu.jo", code: "OBHARA2024" },
        { name: "وادي الشتاء الأساسية", adminEmail: "admin@shita.edu.jo", code: "SHITA2024" },
        { name: "البصة الثانوية", adminEmail: "admin@bassa.edu.jo", code: "BASSA2024" },
        { name: "العراق الأساسية", adminEmail: "admin@iraq.edu.jo", code: "IRAQ2024" },
        { name: "بيادر وادي السير الأساسية", adminEmail: "admin@bayader.edu.jo", code: "BAYADER2024" },
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