SUB_COMMANDS = %w(build detach restore backup list clean db_migrate test)
global_opts = Trollop::options do
  opt :logfile, "Path to logfile to output logs.  Default log to STDOUT"
  banner "available subcommands: #{SUB_COMMANDS.join(' ')}"
  stop_on SUB_COMMANDS
end

cmd = ARGV.shift # get the subcommand
# Parse the subcommand's options.
cmd_opts = case cmd
  when "build" 
    Trollop::options do
      opt :name, "Unique name to be used for all operations regarding this data set.", :type => :string, :required => true, :short => "-n"
      opt :num_vol, "Number of EBS volumes to stripe together with LVM.", :type => :integer, :required => true
      opt :size_vol, "Size of *each EBS volume in Gigabytes", :type => :integer, :required => true
      opt :mount_point, "Mount point where the LVM stripe will be mounted.", :default => "/mnt/ebs"
      opt :device_letters, "Choose the device name suffix(s) for all volumes in the stripe.  Use one letter per volume separated by spaces.  Example --device-letters l m n o p --num-vol 5", :type => :strings, :required => true
      opt :lvm_device_name, "LVM device name.", :type => :string, :required => false, :default => "lvol1"
      opt :lvm_volume_group, "LVM volume group name.", :type => :string, :required => false, :default => "esense-vg-data"
    end
  when "detach"
    Trollop::options do
      opt :name, "Unique name to be used for all operations regarding this data set.", :type => :string, :required => true, :short => "-n"
      opt :device_letters, "Choose the device name suffix(s) for all volumes in the stripe.  Use one letter per volume separated by spaces.  Example --device-letters l m n o p --num-vol 5", :type => :strings, :required => false
      opt :delete, "Specify this to delete the volume after detachment."
    end
  when "db_migrate"
    Trollop::options do
      opt :destructive, "Use this option to cause datamapper to re-create the entire DB.  ERASES ALL DATA!"
    end
  when "test"
    Trollop::options do
      opt :tags, "Run the tag sync test"
      #no options yet, might pass in test to run.
    end
  when "backup"
    Trollop::options do
      opt :name, "Unique name to be used for all operations regarding this data set.", :type => :string, :required => true, :short => "-n"
      opt :pre_hook, "Command to be run just prior to snapshot.", :type => :string
      opt :post_hook, "Command to run just after snapshot.", :type => :string
    end
  when "restore"
    Trollop::options do
      opt :name, "Unique name to be used for all operations regarding this data set.", :type => :string, :required => true, :short => "-n"
    end
  when "list"
    Trollop::options do
      opt :name, "List info about the backup set with the specified name.", :type => :string
      opt :sync, "Sync local database from AWS tags for the specified name.", :type => :string
      opt :tags, "Search for backup metadata in EC2 tags."
    end
  when "clean"
    Trollop::options do
      opt :name, "Target the specified backupset for cleanup operations.", :type => :string, :required => true
      opt :keep, "Number of Snapshot-sets (backups) to keep.", :type => :integer, :default => 10
    end
  else
    Trollop::die "unknown subcommand #{cmd.inspect}"
  end

#puts "Global options: #{global_opts.inspect}"
#puts "Subcommand: #{cmd.inspect}"
#puts "Subcommand options: #{cmd_opts.inspect}"
#puts "Remaining arguments: #{ARGV.inspect}"

if cmd == "db_migrate"
  Ebssense::Startup.orm_init(Dir.pwd + "/ebssense.db")
  if cmd_opts[:destructive]
    DataMapper.auto_migrate!
  else
    DataMapper.auto_upgrade!
  end
elsif cmd == 'build'
  Ebssense::Startup.orm_init(Dir.pwd + "/ebssense.db")
  require 'ebssense/build'
  new_ebs = Ebssense::Build.new(cmd_opts)
  new_ebs.create_fresh_volumes_attach
elsif cmd == 'list'
  Ebssense::Startup.orm_init(Dir.pwd + "/ebssense.db")
  require 'ebssense/list'
  if cmd_opts[:tags_given]
    Ebssense::List.display_tags
  elsif cmd_opts[:sync_given]
    Ebssense::List.sync_tags(cmd_opts[:sync])
    Ebssense::List.display_name(cmd_opts[:sync])
  elsif cmd_opts[:name_given]
    Ebssense::List.display_name(cmd_opts[:name])
  else
    Ebssense::List.display_all
  end
elsif cmd == 'detach'
  Ebssense::Startup.orm_init(Dir.pwd + "/ebssense.db")
  require 'ebssense/detach'
  detach_cmd = Ebssense::Detach.new(cmd_opts)
  detach_cmd.detach_volumes(cmd_opts[:delete])
elsif cmd == 'backup'
  Ebssense::Startup.orm_init(Dir.pwd + "/ebssense.db")
  require 'ebssense/backup'
  new_bak = Ebssense::Backup.new(cmd_opts)
  new_bak.run
elsif cmd == 'restore'
  Ebssense::Startup.orm_init(Dir.pwd + "/ebssense.db")
  require 'ebssense/restore'
  new_restore = Ebssense::Restore.new(cmd_opts)
  new_restore.run
elsif cmd == 'clean'
  Ebssense::Startup.orm_init(Dir.pwd + "/ebssense.db")
  require 'ebssense/clean'
  cleanup = Ebssense::Clean.new(cmd_opts)
  cleanup.run
elsif cmd == 'test'
  require 'rspec'
  Ebssense::Startup.orm_init(Dir.pwd + "/ebssense-TESTING.db")
  spec_dir = File.expand_path(File.join(File.dirname(File.realpath(__FILE__)), "..", "..", "spec"))
  if cmd_opts[:tags]
    run_this = File.join(spec_dir, "tags_spec.rb")
  else
    run_this = File.join(spec_dir, "integration_spec.rb")
  end
  RSpec::Core::Runner::run([run_this], STDERR, STDOUT)
end
