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
        console.log(`✅ Principal for ${school.name} synced`);
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