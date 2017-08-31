require_relative 'report_creator'
require 'byebug'

class Application
  def initialize
    @working_dates = working_dates
    log_in
  end

  def perform
    if ARGV[0]
      ReportCreator.new(Date.parse(ARGV[0])).perform
    else
      @working_dates.each { |date| ReportCreator.new(date).perform }
    end
  end

  private

  def working_dates
    d1 = Date.new(Time.now.year, Time.now.month, 1)
    d2 = Date.new(Time.now.year, Time.now.month, -1)
    (d1..d2).reject { |d| [0, 6].include? d.wday }
  end

  def log_in
    $toggl = TogglV8::API.new(@credentials['toggl']['email'], @credentials['toggl']['pass'])
    Octokit.configure do |c|
      c.login = @credentials['github']['email']
      c.password = @credentials['github']['pass']
    end
  end
end

Application.new.perform
