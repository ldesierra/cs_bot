# CS Trading App

A Rails application for CS trading with Sidekiq background jobs and Telegram bot integration.

## Prerequisites

- Ruby 3.1+
- PostgreSQL
- Redis
- Node.js (for asset compilation)

## Local Development

1. Clone the repository
2. Install dependencies: `bundle install`
3. Setup database: `rails db:create db:migrate`
4. Start Redis server
5. Run the application: `bin/dev`

## Environment Variables

Create a `.env` file with the following variables:

```bash
# Database
DATABASE_URL=postgresql://username:password@localhost:5432/cs_development

# Redis
REDIS_URL=redis://localhost:6379/0

# Rails
RAILS_ENV=development
RAILS_MASTER_KEY=your_master_key_here
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_LEVEL=info

# Sidekiq
SIDEKIQ_CONCURRENCY=5

# Telegram Bot (if using)
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here
```

## Deployment to Heroku

### Prerequisites
- Heroku CLI installed
- Heroku account

### Steps

1. **Create Heroku App**
   ```bash
   heroku create your-app-name
   ```

2. **Add Required Add-ons**
   ```bash
   heroku addons:create heroku-postgresql:mini
   heroku addons:create heroku-redis:mini
   ```

3. **Set Environment Variables**
   ```bash
   heroku config:set RAILS_SERVE_STATIC_FILES=true
   heroku config:set RAILS_LOG_LEVEL=info
   heroku config:set RAILS_ENV=production
   # Add your Telegram bot token if using
   heroku config:set TELEGRAM_BOT_TOKEN=your_token_here
   ```

4. **Deploy**
   ```bash
   git push heroku main
   ```

5. **Run Database Migrations**
   ```bash
   heroku run rails db:migrate
   ```

6. **Scale Dynos**
   ```bash
   heroku ps:scale web=1 worker=1
   ```

### Heroku Configuration

The app is configured with:
- **Web dyno**: Runs the Rails application with Puma
- **Worker dyno**: Runs Sidekiq for background jobs
- **PostgreSQL**: Database
- **Redis**: For Sidekiq job queue and caching

### Monitoring

- View logs: `heroku logs --tail`
- Monitor dynos: `heroku ps`
- Access Rails console: `heroku run rails console`

## Services

- **Sidekiq**: Background job processing
- **PostgreSQL**: Primary database
- **Redis**: Job queue and caching
- **Telegram Bot**: Optional integration for notifications

## Testing

Run the test suite:
```bash
rails test
```
