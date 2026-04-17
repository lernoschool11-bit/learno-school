#!/bin/bash

# --- Learno Deployment Script ---
# Act as a DevOps Engineer
echo "🚀 Initializing Learno Deployment Sequence..."

# Git Init
if [ ! -d ".git" ]; then
    git init
    echo "✅ Git repository initialized."
else
    echo "ℹ️ Git already initialized."
fi

# Add Files
echo "📂 Staging files for commit..."
git add .

# Conventional Commit
echo "💾 Generating conventional commit..."
git commit -m "feat: launch multi-school platform with principal dashboard and content moderation"

# Remote Selection
echo "🔗 GitHub Integration"
read -p "Enter your GitHub Repository URL (e.g., https://github.com/user/repo.git): " REPO_URL

if [ -z "$REPO_URL" ]; then
    echo "❌ Error: Repository URL is required. Deployment aborted."
    exit 1
fi

# Set Remote
git remote add origin $REPO_URL 2>/dev/null || git remote set-url origin $REPO_URL

# Branch renaming (Ensures "main")
git branch -M main

# Push
echo "⬆️ Pushing to GitHub (main)..."
git push -u origin main

echo "🏁 Deployment Complete! Your project is now live on GitHub."
