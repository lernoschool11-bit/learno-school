import { PrismaClient } from '@prisma/client';
import { PrismaNeon } from '@prisma/adapter-neon';
import { Pool, neonConfig } from '@neondatabase/serverless';
import ws from 'ws';
import 'dotenv/config';
import bcrypt from 'bcrypt';

neonConfig.webSocketConstructor = ws;

const prisma = new PrismaClient({
    adapter: new PrismaNeon(new Pool({ connectionString: process.env.DATABASE_URL }) as any) as any
});

async function main() {
    console.log("🌱 Starting seed...");

    const schools = [
        { name: "Marj Al-Hamam", email: "admin@marj.edu.jo", password: "password123", code: "MARJ2024" },
        { name: "Irbid Secondary", email: "admin@irbid.edu.jo", password: "password123", code: "IRBID2024" },
        { name: "Amman Academy", email: "admin@amman.edu.jo", password: "password123", code: "AMMAN2024" },
    ];

    for (const school of schools) {
        let dbSchool = await prisma.school.findUnique({
            where: { name: school.name }
        });

        if (!dbSchool) {
            const hashedAdminPassword = await bcrypt.hash(school.password, 10);
            dbSchool = await prisma.school.create({
                data: {
                    name: school.name,
                    adminEmail: school.email,
                    adminPassword: hashedAdminPassword,
                    teacherSecretCode: school.code,
                    isPasswordChanged: false,
                }
            });
            console.log(`✅ School ${school.name} created`);
        }

        const hashedUserPassword = await bcrypt.hash(school.password, 10);
        await prisma.user.upsert({
            where: { email: school.email },
            update: {
                password: hashedUserPassword,
                role: 'PRINCIPAL',
                school: school.name,
                schoolId: dbSchool.id,
            },
            create: {
                nationalId: `ADMIN_${school.name.toUpperCase().replace(/\s/g, '_')}`,
                fullName: `${school.name} Principal`,
                username: `admin_${school.name.toLowerCase().replace(/\s/g, '_')}`,
                email: school.email,
                password: hashedUserPassword,
                role: 'PRINCIPAL',
                school: school.name,
                schoolId: dbSchool.id,
            }
        });
    }

    console.log("✅ Basic schools and principals synced.");

    // ==================== TEST DATA ====================
    console.log("🧪 Adding Test Data...");

    const testPassword = await bcrypt.hash("12345678", 10);
    const marjSchool = await prisma.school.findUnique({ where: { name: "Marj Al-Hamam" } });

    if (!marjSchool) {
        throw new Error("School 'Marj Al-Hamam' not found. Seed failed.");
    }

    // Create Test Student
    const testUser = await prisma.user.upsert({
        where: { username: "test1" },
        update: {
            password: testPassword,
            role: 'STUDENT',
            school: "Marj Al-Hamam",
            schoolId: marjSchool.id,
            grade: "10",
            section: "A"
        },
        create: {
            nationalId: "TEST001",
            fullName: "Test User",
            username: "test1",
            email: "test1@gmail.com",
            password: testPassword,
            role: 'STUDENT',
            school: "Marj Al-Hamam",
            schoolId: marjSchool.id,
            grade: "10",
            section: "A"
        }
    });
    console.log("✅ Test Student 'test1' created.");

    // Create 5 Test Posts
    for (let i = 1; i <= 5; i++) {
        await prisma.post.create({
            data: {
                content: `Test post number ${i} for demonstration purposes. #Test`,
                authorId: testUser.id,
                schoolId: marjSchool.id,
                type: 'TEXT'
            }
        });
    }
    console.log("✅ 5 Test Posts created.");

    // Create 5 Community Messages
    const roomId = "Marj Al-Hamam_10_A";
    for (let i = 1; i <= 5; i++) {
        await prisma.message.create({
            data: {
                roomId: roomId,
                content: `Test message ${i} in the community chat.`,
                userId: testUser.id,
                type: 'text'
            }
        });
    }
    console.log("✅ 5 Community Messages created.");

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