namespace :my_service do
  desc "Run MyService every minute"
  task :run do
    # Manually load the Rails app without full environment
    require File.expand_path('../../config/application', __dir__)
    Rails.application.initialize!

    ApiChecker.call
  end
end
