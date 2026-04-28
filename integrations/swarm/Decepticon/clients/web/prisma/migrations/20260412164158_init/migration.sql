-- CreateEnum
CREATE TYPE "TargetType" AS ENUM ('web_url', 'ip_range');

-- CreateEnum
CREATE TYPE "EngagementStatus" AS ENUM ('draft', 'planning', 'running', 'completed', 'failed');

-- CreateTable
CREATE TABLE "Engagement" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "targetType" "TargetType" NOT NULL,
    "targetValue" TEXT NOT NULL,
    "status" "EngagementStatus" NOT NULL DEFAULT 'draft',
    "userId" TEXT NOT NULL DEFAULT 'local',
    "threadId" TEXT,
    "workspacePath" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Engagement_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Engagement_userId_idx" ON "Engagement"("userId");

-- CreateIndex
CREATE INDEX "Engagement_status_idx" ON "Engagement"("status");
