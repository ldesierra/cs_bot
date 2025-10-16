#!/bin/bash

# Heroku Deployment Script for CS Trading App
# This script automates the deployment process to Heroku

set -e

echo "🚀 Starting Heroku deployment process..."

# Check if Heroku CLI is installed
if ! command -v heroku &> /dev/null; then
    echo "❌ Heroku CLI is not installed. Please install it first:"
    echo "   https://devcenter.heroku.com/articles/heroku-cli"
    exit 1
fi

# Check if user is logged in to Heroku
if ! heroku auth:whoami &> /dev/null; then
    echo "❌ Please log in to Heroku first:"
    echo "   heroku login"
    exit 1
fi

# Get app name from user or use default
if [ -z "$1" ]; then
    echo "📝 Enter your Heroku app name (or press Enter to use 'cs-trading-app'):"
    read -r APP_NAME
    APP_NAME=${APP_NAME:-cs-trading-app}
else
    APP_NAME=$1
fi

echo "📱 Using app name: $APP_NAME"

# Create Heroku app if it doesn't exist
if ! heroku apps:info --app "$APP_NAME" &> /dev/null; then
    echo "🆕 Creating new Heroku app: $APP_NAME"
    heroku create "$APP_NAME"
else
    echo "✅ App $APP_NAME already exists"
fi

# Add required add-ons
echo "🔧 Adding required add-ons..."
heroku addons:create heroku-postgresql:mini --app "$APP_NAME" || echo "PostgreSQL addon already exists"
heroku addons:create heroku-redis:mini --app "$APP_NAME" || echo "Redis addon already exists"

# Set environment variables
echo "⚙️  Setting environment variables..."
heroku config:set RAILS_SERVE_STATIC_FILES=true --app "$APP_NAME"
heroku config:set RAILS_LOG_LEVEL=info --app "$APP_NAME"
heroku config:set RAILS_ENV=production --app "$APP_NAME"

# Deploy to Heroku
echo "🚀 Deploying to Heroku..."
git push heroku main

# Run database migrations
echo "🗄️  Running database migrations..."
heroku run rails db:migrate --app "$APP_NAME"

# Scale dynos
echo "📈 Scaling dynos..."
heroku ps:scale web=1 worker=1 --app "$APP_NAME"

echo "✅ Deployment completed successfully!"
echo "🌐 Your app is available at: https://$APP_NAME.herokuapp.com"
echo ""
echo "📊 Useful commands:"
echo "   heroku logs --tail --app $APP_NAME"
echo "   heroku ps --app $APP_NAME"
echo "   heroku run rails console --app $APP_NAME"
echo ""
echo "💡 Don't forget to set your Telegram bot token if you're using it:"
echo "   heroku config:set TELEGRAM_BOT_TOKEN=your_token_here --app $APP_NAME"
