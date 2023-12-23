class ScrapeJob < ApplicationJob
  queue_as :default

  def perform
    puts "I am starting now"
    sleep 5
    puts "Done!"
  end
end
