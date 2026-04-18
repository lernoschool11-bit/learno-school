import 'dotenv/config';
import { PrismaClient } from "@prisma/client";
import { PrismaNeon } from "@prisma/adapter-neon";
import { Pool, neonConfig } from "@neondatabase/serverless";
import ws from "ws";

neonConfig.webSocketConstructor = ws;

const connectionString = `${process.env.DATABASE_URL}`;

if (!process.env.DATABASE_URL) {
  console.error("❌ DATABASE_URL is MISSING from environment variables!");
} else {
  console.log("✅ DATABASE_URL is present, attempting to connect...");
}

const pool = new Pool({ connectionString });
const adapter = new PrismaNeon(pool as any);

const prisma = new PrismaClient({ adapter });

export { prisma };
export default prisma;