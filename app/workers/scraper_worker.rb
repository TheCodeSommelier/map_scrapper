class ScraperWorker
  include Sidekiq::Worker

  def perform
    puts "!!!Scraping scraping!!!"
  end
end
