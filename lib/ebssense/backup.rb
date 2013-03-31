require 'ebssense/lvm_aws_helper.rb'
require 'ebssense/run_cmd_helper.rb'

module Ebssense
  class Backup
    include Ebssense::LvmAwsHelper
    include Ebssense::RunCmdHelper
    include Ebssense::TagSync

    def initialize(opts)
      @options = opts
      @ec2 = AWS::EC2.new()
      @log = Logger.new(STDOUT)
      @log.level = Logger::INFO
      unless ENV['AWS_SECRET_KEY'] && ENV['AWS_ACCESS_KEY']
        puts "You must set the environment variables AWS_SECRET_KEY and AWS_ACCESS_KEY."
        exit 1
      end
      @backupmeta = Backupmeta.first(:name => opts[:name])
      @attached_volset = @backupmeta.volsets.first(:attached => true)
      unless @backupmeta && @attached_volset
        info "FATAL: could not find backup metadata for #{opts[:name]} in the database. Aborting."
        exit 1 unless @options[:device_letters]
      end
      self
    end

    def run
      info "cleanup old LVM snapshots if they exist."
      run_cmd("umount #{lvm_snapshot_device}", true)
      run_cmd("lvremove -f #{lvm_snapshot_device}", true)

      info "running pre-hook command."
      if @options[:pre_hook_given]
        run_cmd(@options[:pre_hook])
      else
        run_cmd("sync")
        run_cmd("sync")
      end

      info "taking LVM snapshot."
      run_cmd("lvcreate --snapshot --name #{lvm_snap_name} #{lvm_device_name} -l 15%VG")

      # run post-hook command
      info "running post-hook command."
      if @options[:post_hook_given]
        run_cmd(@options[:post_hook])
      end

      # take the EBS snapshots
      new_snapset = Snapset.create(:status => "in-progress")
      @backupmeta.snapsets << new_snapset
      snap_status = []
      @attached_volset.volumes.each do |volume| 
        ec2volume = @ec2.volumes[volume.id]
        ec2snapshot = ec2volume.create_snapshot("#{@backupmeta.name}")
        info "created snap: #{ec2snapshot.id} from volume #{volume.id}"
        new_snapset.snapshots << Snapshot.create(:id => ec2snapshot.id, :device_letter => volume.device_letter)
        new_snapset.started_at = ec2snapshot.start_time.to_s
        snap_status << ec2snapshot
      end
      new_snapset.save
      
      # verify EBS snapshots complete successful
      snap_status.each do |snapshot|
        info "waiting for snapshot to complete.."
        sleep 1 until [:completed, :error].include?(snapshot.status)
        new_snapset.status = "error" if snapshot.status == :error
      end
      new_snapset.status = "good" unless new_snapset.status == "error"
      new_snapset.save
      sync_to_tags(new_snapset)
    end
  end
end
