import { PrismaClient } from "@prisma/client";

// On Render (Standard Web Service), we don't need the serverless adapter.
// Standard PrismaClient will use DATABASE_URL from environment automatically.
const prisma = new PrismaClient();

export { prisma };
export default prisma;