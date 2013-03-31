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

# Stay compatible with ALL the aws style tools
ENV['AWS_ACCESS_KEY_ID'] = ENV['AWS_ACCESS_KEY']
ENV['AWS_SECRET_ACCESS_KEY'] = ENV['AWS_SECRET_KEY']


module Ebssense
  class Startup
    # db_path == the sqlite db path
    def self.orm_init(db_path, logger=$stdout)
      DataMapper::Logger.new(logger, :info)

# Load our ORM libs.
      dbfdir = File.expand_path(File.join(File.dirname(File.realpath(__FILE__)), "ebssense", "db"))
      dblibs = Dir.glob(File.join(dbfdir, "*.rb"))
      dblibs.each do |lib|
        require lib
      end

      sqlite = "sqlite:///#{db_path}"
      puts "using sqlite endpoint: #{sqlite}"
      DataMapper.setup(:default, sqlite)

      DataMapper.finalize
    end
  end
end
