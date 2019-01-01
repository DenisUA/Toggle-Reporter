require_relative 'report_creator'
require 'yaml'
require 'byebug'

class Application
  def initialize
    @working_dates = working_dates
    @credentials = YAML.load_file('config/application.yml')
    log_in
  end

  def perform
    if ARGV[0]
      ReportCreator.new(Date.parse(ARGV[0]), @credentials).perform
    else
      @working_dates.each { |date| ReportCreator.new(date, @credentials).perform }
    end
  end

  private

  def working_dates
    d1 = Date.new(Time.now.year, Time.now.month, 1)
    d2 = Date.new(Time.now.year, Time.now.month, -1)
    (d1..d2).reject { |d| [0, 6].include? d.wday }
  end

  def log_in
    $toggl_api = TogglV8::API.new(@credentials['toggl']['api_token'])
    Octokit.configure do |c|
      c.login = @credentials['github']['email']
      c.password = @credentials['github']['pass']
    end
  end
end

Application.new.perform
