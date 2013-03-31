require 'ebssense/lvm_aws_helper.rb'
require 'ebssense/run_cmd_helper.rb'
module Ebssense
  class Clean
    include Ebssense::LvmAwsHelper
    include Ebssense::RunCmdHelper

    def initialize(opts)
      @options = opts
      init_helper
      @backupmeta = Backupmeta.first(:name => opts[:name])
    end

    def run
      sets = @backupmeta.snapsets.all(:order => [:started_at.desc])
      info "Found #{sets.size} total snapshot sets.  Keeping the latest #{options[:keep]} sets."
      keep_these = sets.shift(options[:keep])
      unless keep_these < options[:keep]
        info "Found #{sets.size} extra snapshot sets to cleanup."
        sets.each do |expired|
          expired.snapshots.each do |snap|
            info "Cleaning snapshot: #{snap.id}"
            @ec2.snapshots[snap.id].delete
          end
          expired.destroy
        end
      end
    end
  end
end


