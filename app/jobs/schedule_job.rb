class ScheduleJob < ApplicationJob
  queue_as :scheduler

  def perform
    next_week = 1.week.from_now
    start_of_nw = next_week.beginning_of_week
    seconds_in_nw = (start_of_nw + 1.week) - start_of_nw
    next_run_time = start_of_nw + rand(seconds_in_nw)

    puts "This is next_week"
    p next_week

    puts "This is start_of_nw"
    p start_of_nw

    puts "This is seconds_in_nw"
    p seconds_in_nw

    puts "This is next_run_time"
    p next_run_time

    ScraperWorker.perform_at(next_run_time)
  end
end
