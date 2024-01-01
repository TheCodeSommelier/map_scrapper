class CleanDatabaseJob < ApplicationJob
  include Sidekiq::Status

  queue_as :database_cleaning

  def perform
    # Map.destroy_all
  end
end
