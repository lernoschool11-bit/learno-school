import 'dotenv/config';
import { PrismaClient } from "@prisma/client";
import { PrismaNeon } from "@prisma/adapter-neon";
import { neon } from "@neondatabase/serverless";

let prisma: PrismaClient;

function getPrisma() {
  if (!prisma) {
    const url = process.env.DATABASE_URL;
    if (!url) throw new Error("DATABASE_URL not set");
    const sql = neon(url);
    const adapter = new PrismaNeon(sql as any);
    prisma = new PrismaClient({ adapter });
  }
  return prisma;
}

export { getPrisma as prisma };
export default getPrisma();