class ScheduleJob < ApplicationJob
  queue_as :scheduler

  def perform
    minute = rand(1..4)
    next_run_time = Time.now + minute.minutes
    ScraperWorker.perform_at(next_run_time)
  end
end
