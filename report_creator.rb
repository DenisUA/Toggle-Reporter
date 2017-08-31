require 'togglv8'
require 'octokit'
require 'json'
require 'yaml'

class ReportCreator
  def initialize(date)
    @credentials = YAML.load_file('config/application.yml')
    @commits = []
    @tags = []
    @date = date
  end

  def perform
    log_in && process_commits && create_entry
  end

  private

  def log_in
    @toggl = TogglV8::API.new(@credentials['toggl']['email'], @credentials['toggl']['pass'])
    Octokit.configure do |c|
      c.login = @credentials['github']['email']
      c.password = @credentials['github']['pass']
    end
  end

  def process_commits
    collect && filter && collect_names && create_tags
  end

  def collect
    @credentials['github']['repos'].split(', ').each do |repo|
      @commits |= Octokit.commits_on(repo, @date, @credentials['github']['branch'])
    end
  end

  def filter
    @commits.select! { |c| c.commit.author.name == @credentials['github']['name'] }
    @commits.reject! { |c| c.commit.message.match(/Merge/i) }
    puts @commits.nil? ? "#{@date} - zero commits" : "#{@date} - #{@commits.count} commits"
    true
  end

  def collect_names
    @commit_names = @commits.map { |c| c.commit.message }
  end

  def create_tags
    @commit_names.each { |name| @tags << match_tag(name.downcase) }
  end

  def match_tag(name)
    if name =~ /fix/i
      'Fix'
    elsif name =~ /feature/i
      'Feature'
    elsif name =~ /refactor/i
      'Enhancement'
    else
      'Update'
    end
  end

  def create_entry
    return if @commit_names.empty?
    start_at = DateTime.new(@date.year, @date.month, @date.day, 11, rand(0..15), 0, '+03:00')
    data = {
      'description' => @commit_names.join(' / '),
      'wid' => @toggl.my_workspaces(@toggl.me).first['id'],
      'duration' => rand(28_700..29_200),
      'start' => @toggl.iso8601(start_at.to_datetime),
      'pid' => @credentials['toggl']['pid'].to_i,
      'tags' => @tags.uniq
    }
    @toggl.create_time_entry(data)
  end
end
