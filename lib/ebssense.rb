#!/usr/bin/ruby

require 'ebssense/version'
require 'data_mapper'
require 'dm-validations'
require 'aws-sdk'
require 'trollop'
require 'ebssense/lvm_aws_helper.rb'
require 'ebssense/run_cmd_helper.rb'
require 'ebssense/tag_sync.rb'
require 'logger'
require 'rubygems'
require 'net/http'

# Stay compatible with ALL the aws style tools
ENV['AWS_ACCESS_KEY_ID'] = ENV['AWS_ACCESS_KEY']
ENV['AWS_SECRET_ACCESS_KEY'] = ENV['AWS_SECRET_KEY']


module Ebssense
  class Startup
    # db_path == the sqlite db path
    def self.orm_init(cmd_opts)
      db_path = cmd_opts[:sqlite]
      logtarget = cmd_opts[:logfile]
      logtarget ||= $stdout
      loglevel = :info
      loglevel = :debug if cmd_opts[:debug]
      DataMapper::Logger.new(logtarget, loglevel)

# Load our ORM libs.
      dbfdir = File.expand_path(File.join(File.dirname(File.realpath(__FILE__)), "ebssense", "db"))
      dblibs = Dir.glob(File.join(dbfdir, "*.rb"))
      dblibs.each do |lib|
        require lib
      end

      sqlite = "sqlite:///#{db_path}"
      puts "using sqlite endpoint: #{sqlite}"
      DataMapper.setup(:default, sqlite)

      DataMapper.auto_upgrade!

      DataMapper.finalize
    end
  end
end
