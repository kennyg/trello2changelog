require "rubygems"
require "bundler"
require "dotenv/tasks"

require_relative "lib/importer"

Bundler.setup

desc "Import from Trello board"
task :import => :dotenv do
  Importer.new(File.dirname(__FILE__)).import ENV["ISSUE"]
end

