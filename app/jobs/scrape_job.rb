class ScrapeJob < ApplicationJob
  queue_as :default

  def perform
    puts "I'm doing it"
  end
end
