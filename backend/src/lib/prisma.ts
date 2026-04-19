import { PrismaClient } from "@prisma/client";
import { PrismaNeon } from "@prisma/adapter-neon";
import { neon } from "@neondatabase/serverless";

const sql = neon(process.env.DATABASE_URL!);
const adapter = new PrismaNeon(sql as any);
const prisma = new PrismaClient({ adapter });

export { prisma };
export default prisma;