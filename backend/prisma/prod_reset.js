const { execSync } = require('child_process');

process.env.DATABASE_URL = "postgresql://neondb_owner:npg_C8gXV4kUoisE@ep-icy-flower-anklw6at-pooler.c-6.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require";

try {
    console.log("🚀 Running reset on PRODUCTION...");
    execSync("npx ts-node prisma/reset_data.ts", { stdio: 'inherit' });
    
    console.log("🌱 Running seed on PRODUCTION...");
    execSync("npx prisma db seed", { stdio: 'inherit' });
    
    console.log("✅ Production reset and seed complete!");
} catch (error) {
    console.error("❌ Error during production reset:", error.message);
}
