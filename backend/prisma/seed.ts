import { PrismaClient } from '@prisma/client';
import 'dotenv/config';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
    console.log("🌱 Starting seed...");

    // إنشاء كافة مدارس لواء وادي السير (51 مدرسة)
    const wadiSeerSchools = [
        "وادي السير الثانوية للبنين", "وادي السير الثانوية للبنات", "البيادر الثانوية للبنين", "البيادر الثانوية للبنات", "مرج الحمام الثانوية للبنين", 
        "Marj Al-Hamam", "مرج الحمام الثانوية للبنات", "عراق الأمير الثانوية للبنين", "عراق الأمير الثانوية للبنات", "أم عبهرة الثانوية للبنات", 
        "البصة الأساسية المختلطة", "حي القيسية الأساسية المختلطة", "وادي السير الأساسية للبنات الأولى", "وادي السير الأساسية للبنات الثانية", "مرج الحمام الأساسية للبنين", 
        "خولة بنت الأزور الأساسية للبنات", "أسماء بنت أبي بكر الثانوية للبنات", "بدر الأساسية للبنين", "أم السماق الجنوبي الأساسية المختلطة", "وادي الشتاء الأساسية المختلطة", 
        "الوفاق الأساسية للبنات", "خربة سارة الأساسية للبنات", "مرج الحمام الأساسية للبنات", "الدبة الأساسية المختلطة", "البحاث الأساسية المختلطة", 
        "صناعة وادي السير الثانوية للبنين", "الظهير الأساسية المختلطة", "زبود الأساسية المختلطة", "أم الأسود الأساسية المختلطة", "وادي السير الأساسية للبنين", 
        "البيادر الأساسية للبنين", "وادي السير الأساسية المهنية", "السويسة الأساسية المختلطة", "الألمانية الأساسية للبنات", "خربة سارة الثانوية للبنين", 
        "بلال الأساسية للبنين", "الملكة نور الأساسية للبنات", "الرهوة الأساسية المختلطة", "الروضة الأساسية المختلطة", "الملكة رانيا العبد الله الثانوية للبنات", 
        "مرج الحمام الأساسية المختلطة", "أم السماق الشمالي الأساسية للبنات", "الرونق الأساسية للبنات", "الأمير حمزة الأساسية للبنين", "وادي السير الحديثة الأساسية", 
        "حي الدير الأساسية المختلطة", "أم عبهرة الثانوية للبنين", "البصة الثانوية للبنين", "عراق الأمير الأساسية للبنين", "عراق الأمير الأساسية للبنات", 
        "خربة سارة الأساسية للبنين"
    ];

    const schoolsData = wadiSeerSchools.map((name, index) => ({
        name,
        adminEmail: `admin.ws${index + 1}@wadiseer.edu.jo`,
        code: `WS${1000 + index}`
    }));

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
        const adminUsername = `admin_${data.code.toLowerCase()}`;
        const adminNationalId = `ADMIN_${data.code.toUpperCase()}`;

        await prisma.user.upsert({
            where: { email: data.adminEmail },
            update: {
                password: hashedPassword,
                role: 'PRINCIPAL',
                school: school.name,
                schoolId: school.id,
            },
            create: {
                nationalId: adminNationalId,
                fullName: `${school.name} Principal`,
                username: adminUsername,
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