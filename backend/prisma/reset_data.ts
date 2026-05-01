import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log("🔥 Starting full database reset...");

    // 1. Delete all data in order of dependency
    console.log("🗑️ Deleting all records...");
    
    await prisma.grade.deleteMany();
    await prisma.directMessage.deleteMany();
    await prisma.conversation.deleteMany();
    await prisma.message.deleteMany();
    await prisma.notification.deleteMany();
    await prisma.follow.deleteMany();
    await prisma.comment.deleteMany();
    await prisma.like.deleteMany();
    await prisma.post.deleteMany();
    await prisma.submission.deleteMany();
    await prisma.assignment.deleteMany();
    await prisma.question.deleteMany();
    await prisma.quiz.deleteMany();
    await prisma.onlineClass.deleteMany();
    await prisma.user.deleteMany();
    await prisma.school.deleteMany();

    console.log("✅ Database is now empty.");
    console.log("🏁 Reset finished successfully!");
}

main()
    .catch((e) => {
        console.error("❌ Reset failed:", e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
