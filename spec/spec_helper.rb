ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
require "rspec/rails"
require "sidekiq/testing"

Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :rspec
  config.include FactoryGirl::Syntax::Methods

  config.before :suite do
    MongoMapper.database.collections.select {|c| c.name !~ /system/ }.each(&:drop)
  end

  config.before :each do
    ActionMailer::Base.deliveries.clear
  end

  config.after :suite do
    MongoMapper.database.collections.select {|c| c.name !~ /system/ }.each(&:drop)
  end
end