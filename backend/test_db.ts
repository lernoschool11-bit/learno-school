import prisma from './src/lib/prisma';

async function main() {
  const users = await prisma.user.findMany({
    select: { email: true, role: true, fullName: true, school: true, schoolId: true }
  });
  console.log('--- USERS ---');
  console.log(users);
  
  const schools = await prisma.school.findMany();
  console.log('--- SCHOOLS ---');
  console.log(schools);
}

main().catch(console.error).finally(() => prisma.$disconnect());
