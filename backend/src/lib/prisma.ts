import 'dotenv/config';
import { PrismaClient } from "@prisma/client";
import { PrismaNeon } from "@prisma/adapter-neon";
import { neon } from "@neondatabase/serverless";

const connectionString = process.env.DATABASE_URL;
console.log("DATABASE_URL exists:", !!connectionString);

if (!connectionString) {
  throw new Error("DATABASE_URL is not set!");
}

const sql = neon(connectionString);
const adapter = new PrismaNeon(sql as any);
const prisma = new PrismaClient({ adapter });

export { prisma };
export default prisma;