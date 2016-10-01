require "trello"
require "pathname"
require "fileutils"
require_relative "importer/meta"
require_relative "importer/post"

Trello.configure do |config|
  config.developer_public_key = ENV["TRELLO_DEVELOPER_PUBLIC_KEY"]
  config.member_token = ENV["TRELLO_MEMBER_TOKEN"]
end

class Importer
  attr_reader :root_dir
  def initialize root_dir
    @root_dir = root_dir
  end

  def issues_dir
    @issues_dir ||= File.join root_dir, "source"
  end

  def next_issue_number
    Pathname.new(issues_dir)
      .children
      .select { |child| child.directory? }
      .map    { |dir| dir.basename.to_s }
      .select { |dirname| dirname.match /\A\d/ }
      .map(&:to_i).sort.last.succ.to_s
  end

  def import issue_number
    start_time = Time.now

    if issue_number.nil?
      issue_number = next_issue_number

      puts "No issue number specified. Guessing you want ##{issue_number}..."
    end

    board_source = ENV["TRELLO_BOARD_SOURCE"]
    board_name = "#{board_source} ##{issue_number}"

    board = Trello::Board.all.find { |b| b.name == board_name }

    if board.nil?
      abort "Unable to find board named: #{board_name}"
    end

    lists = board.lists
    meta = Meta.new lists.shift

    issue_dir = File.join issues_dir, issue_number
    FileUtils.mkdir_p issue_dir
    issue_file = File.join issue_dir, "index.html.erb"

    template = File.open issue_file, "w"

    # DISCLAIMER: we are using Ruby to generate ERB, which is then
    # consumed by Middleman, which outputs HTML. This is not ideal.
    # We will eventually cut out the Middleman (see what I did there?)
    # and use ERB directly to generate HTML, but this got us up and
    # publishing quickly. Pragmatism can be ugly, but wins the day.
    template.puts <<-DOC.gsub(/^ {4}/, '')
    <%
      @title = "Issue ##{issue_number}"
      @published_at = "#{meta.published_at}"
      @preview_text = "#{meta.preview_text}"
      @editors_note = "#{meta.editors_note}"
    %>

    <% content_for :preview_text, @preview_text %>
    <% content_for :title, @title %>
    DOC

    lists.each do |list|
      next if list.cards.empty?

      template.puts "\n<% content_block do %>\n"
      template.puts "\n  <h3>#{list.name}</h3>\n\n"

      list.cards.each do |card|
        post = Post.new card

        if card == list.cards.last
          template.puts "  <div class='list-item last-of-type'>"
        else
          template.puts "  <div class='list-item'>"
        end

        if post.draft?
          next
        end

        if post.sponsored?
          template.puts "    <h5>Sponsored</h5>"
        end

        if post.link !~ URI::regexp
          puts "WARNING: #{post.title} does not have a valid link!"
          template.puts "    <h5 class='item--error'>Whoops</h5>"
        end

        template.puts "    <h2><a href='#{post.link}'>#{post.title}</a></h2>"
        template.puts "    #{post.body}"
        template.puts "  </div>\n\n"
      end

      template.puts "<% end %>\n"
    end

    template.close

    total_time = (Time.now - start_time).round 2
    puts "Generated issue ##{issue_number} in #{total_time} seconds."
  end
end
