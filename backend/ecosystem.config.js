// ═══════════════════════════════════════════════════════════
// PM2 Ecosystem Config — "Ghost Process" for Learno Backend
// ═══════════════════════════════════════════════════════════
// Usage:
//   npm run service:start   → start as background daemon
//   npm run service:stop    → gracefully stop
//   npm run service:restart → restart
//   npm run service:logs    → tail logs
//   pm2 status              → see all processes
// ═══════════════════════════════════════════════════════════

module.exports = {
  apps: [
    {
      name: 'learno-backend',
      script: './dist/server.js',
      cwd: './',

      // ── Restart Policy ──────────────────────────────────
      autorestart: true,             // auto-restart on crash
      max_restarts: 15,              // max 15 restarts in a window
      restart_delay: 2000,           // 2s delay between restarts
      max_memory_restart: '512M',    // restart if memory exceeds 512MB
      kill_timeout: 5000,            // 5s grace period on stop

      // ── Environment ─────────────────────────────────────
      env: {
        NODE_ENV: 'production',
      },
      env_development: {
        NODE_ENV: 'development',
      },

      // ── Logging ─────────────────────────────────────────
      error_file: './logs/pm2-error.log',
      out_file: './logs/pm2-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,

      // ── Advanced ────────────────────────────────────────
      instances: 1,                  // single instance (increase for clustering)
      exec_mode: 'fork',             // fork mode (use 'cluster' for multi-core)
      watch: false,                  // don't watch files in production
      listen_timeout: 10000,         // 10s for app to start listening
    },
  ],
};
