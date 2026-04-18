import 'dotenv/config';
import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";
import pkg from "pg";

const { Pool } = pkg;

const connectionString = process.env.DATABASE_URL!;

const pool = new Pool({
  connectionString,
  ssl: { rejectUnauthorized: false },
  max: 1
});

const adapter = new PrismaPg(pool, { schema: "public" });
export const prisma = new PrismaClient({ adapter });
export default prisma;