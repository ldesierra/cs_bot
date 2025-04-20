set :environment, "development" # or "production"
set :output, "log/cron.log"

every 20.seconds do
  runner "SecondlyJob.perform_async"
end

every 1.hour do
  runner "HourlyJob.perform_async"
end
