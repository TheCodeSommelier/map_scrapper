class ScraperWorker
  include Sidekiq::Worker

  def perform
    db_cleaning_job_id = CleanDatabaseJob.perform_now
    return if Sidekiq::Status.failed?(db_cleaning_job_id)

    scrape_job_s_id = ScrapeSJob.perform_later
    scrape_job_r_id = ScrapeRJob.perform_later
    scrape_job_l_id = ScrapeLJob.perform_later
    return if Sidekiq::Status.failed?(scrape_job_s_id) && Sidekiq::Status.failed?(scrape_job_r_id) && Sidekiq::Status.failed?(scrape_job_l_id)

    ScheduleJob.perform_later
  end
end
