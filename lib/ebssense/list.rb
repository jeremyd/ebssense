require 'ruport'
require 'ebssense/tag_sync'

module Ebssense
  class List

    include Ebssense::TagSync
    include Ebssense::RunCmdHelper
    include Ebssense::LvmAwsHelper

    def initialize()
      init_helper({})
      self
    end

    def self.sync_tags(name)
      s = self.new
      s.sync_from_tags(name)
    end

    def self.display_tags
      s = self.new
      vt = Ruport::Data::Table.new(:column_names => ["Backup sets found in EC2 tags."])
      s.all_names.each do |name|
        vt << [name]
      end
      puts vt.to_s
    end

    def self.display_all
      t = Ruport::Data::Table.new(:column_names => ["Existing backup metadata sets (by name)", "attached?", "device letters"])
      Backupmeta.all.each do |b| 
        is_attached = b.volsets.first(:attached => true)
        display_this = ""
        if is_attached
          display_this = "Yes"
        else
          display_this = "No"
        end
        t << [b.name, display_this, b.device_letters.join(",")]
      end
      puts t.to_s
    end
    
    def self.display_name(name)
      thisbak = Backupmeta.first(:name => name)
      unless thisbak
        puts "Failure: could not find backupset with #{name}."
        exit 1
      end
      puts "Listing backup metadata set for: #{name}"
      vt = Ruport::Data::Table.new(:column_names => ["Volume Set", "AWS Volume IDs"])
      thisbak.volsets.each do |volset|
        vt << [volset.id, volset.volumes.collect { |c| c.id }]
      end
      puts vt.to_s
      vs = Ruport::Data::Table.new(:column_names => ["AWS Snapshot 'start-time'", "AWS Snapshot IDs"])
      thisbak.snapsets.each do |snapset|
        vs << [snapset.started_at, snapset.snapshots.collect { |c| c.id }]
      end
      puts vs.to_s
    end
  end
end
