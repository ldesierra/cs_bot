namespace :my_service do
  desc "Run MyService every minute"
  task run: :environment do
    ApiChecker.call
  end
end
