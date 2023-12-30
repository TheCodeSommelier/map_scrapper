class ScheduleJob < ApplicationJob
  queue_as :scheduler

  def perform
    minute = rand(5..10)
    next_run_time = Time.now + minute.minutes
    ScraperWorker.perform_at(next_run_time)
  end
end
