require 'togglv8'
require 'octokit'
require 'json'

class ReportCreator
  def initialize(date, credentials)
    @commits = []
    @tags = []
    @date = date
    @credentials = credentials
  end

  def perform
    process_commits && create_entry
  end

  private

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
    user = $toggl_api.me(all=true)
    workspace_id = $toggl_api.my_workspaces(user).first['id']
    $toggl_api.create_time_entry({
      'description' => @commit_names.join(' / '),
      'wid' => workspace_id,
      'duration' => rand(28_700..29_200),
      'start' => $toggl_api.iso8601(start_at.to_datetime),
      'pid' => @credentials['toggl']['pid'].to_i,
      'tags' => @tags.uniq
    })
  end
end
