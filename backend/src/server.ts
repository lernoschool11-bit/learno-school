import 'dotenv/config';
import http from "http";
import app from "./app";
import { initSocket } from "./socket";
import prisma from "./lib/prisma";

const PORT = process.env.PORT || 8000;

const httpServer = http.createServer(app);

initSocket(httpServer);

// Fail-safe: Ensure columns exist in DB manually if migrations failed
async function ensureColumns() {
  try {
    console.log("Checking and fixing database columns...");
    await prisma.$executeRawUnsafe(`ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "aiRequestsCount" INTEGER DEFAULT 0`);
    await prisma.$executeRawUnsafe(`ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "lastAiRequest" TIMESTAMP WITH TIME ZONE`);
    console.log("Database columns verified.");
  } catch (err) {
    console.error("Error ensuring columns:", err);
  }
}

async function start() {
  await ensureColumns();
  httpServer.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
}

start();