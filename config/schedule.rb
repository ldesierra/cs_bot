set :environment, "development" # or "production"
set :output, "log/cron.log"

every 1.minute do
  runner "ApiChecker.call"
end
