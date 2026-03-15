/*
  Warnings:

  - You are about to drop the column `sirajId` on the `User` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[nationalId]` on the table `User` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[username]` on the table `User` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `nationalId` to the `User` table without a default value. This is not possible if the table is not empty.
  - Added the required column `password` to the `User` table without a default value. This is not possible if the table is not empty.
  - Added the required column `username` to the `User` table without a default value. This is not possible if the table is not empty.

*/
-- DropIndex
DROP INDEX "User_sirajId_key";

-- AlterTable
ALTER TABLE "User" DROP COLUMN "sirajId",
ADD COLUMN     "classes" TEXT,
ADD COLUMN     "dob" TEXT,
ADD COLUMN     "grade" TEXT,
ADD COLUMN     "nationalId" TEXT NOT NULL,
ADD COLUMN     "password" TEXT NOT NULL,
ADD COLUMN     "section" TEXT,
ADD COLUMN     "subjects" TEXT[],
ADD COLUMN     "username" TEXT NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "User_nationalId_key" ON "User"("nationalId");

-- CreateIndex
CREATE UNIQUE INDEX "User_username_key" ON "User"("username");
