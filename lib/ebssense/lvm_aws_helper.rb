module Ebssense
  module LvmAwsHelper

    def init_helper
      #info target.block_device_mappings.inspect
      @ec2 = AWS::EC2.new()
      @log = Logger.new(STDOUT)
      @log.level = Logger::INFO
      unless ENV['AWS_SECRET_KEY'] && ENV['AWS_ACCESS_KEY']
        puts "You must set the environment variables AWS_SECRET_KEY and AWS_ACCESS_KEY."
        exit 1
      end
    end

    # Find the server's identity, return aws-sdk instance object.
    # Requires cloud-init on image.
    def target
      # This file is a link to a file who's filename is the instance id of this instance.
      @instance_id ||= File.basename(File.readlink("/var/lib/cloud/instance"))
      instance = @ec2.instances[@instance_id]
      raise "FATAL: the instance id we found doesn't exist" unless instance.exists?
      raise "FATAL: the instance we're on status isn't :running" unless instance.status == :running
      instance
    end

    def wait_for_local_attach(device)
      timeout = 120
      while(timeout < 120)
        `file #{device}`
        return true if $?.success?
        sleep 1
        timeout+=1
      end
# apparently this isn't enough.  For now sleep a few more seconds so that the next LVM command can use the device.
      sleep 5
      false
    end

    # Returns an array of full device names
    # TODO: detect xvd or sd
    def local_device_names
      @options[:device_letters].collect { |suffix| "/dev/xvd#{suffix}" }
    end

    def volume_group_name
      if @options[:lvm_volume_group]
        return @options[:lvm_volume_group]
      else
        check_phys = "/dev/xvd#{@backupmeta.device_letters.first}"
        raw_pvdisp_vg = `pvdisplay -c |grep #{check_phys}|cut -d: -f2`.chomp
        raw_pvdisp_vg.gsub!(/^\s+/,"")
        return raw_pvdisp_vg
      end
    end

    def lvm_device_name
      if @options[:lvm_device_name]
        return "/dev/#{@options[:lvm_volume_group]}/#{@options[:lvm_device_name]}"
      else
        check_phys = "/dev/xvd#{@backupmeta.device_letters.first}"
        raw_pvdisp_vg = `pvdisplay -c |grep #{check_phys}|cut -d: -f2`.chomp
        raw_pvdisp_vg.gsub!(/^\s+/,"")
        raw_lvdisp_lvol = `lvdisplay -c |grep #{raw_pvdisp_vg}|grep -v snapshot|cut -d: -f1`.chomp
        raw_lvdisp_lvol.gsub!(/^\s+/,"")
	return raw_lvdisp_lvol
      end
    end

    def lvm_snap_name
      lvm_snapshot_device.split(/\//).last
    end

    def lvm_volume_name
      lvm_device_name.split(/\//).last

    end

    def lvm_snapshot_device
      lvm_device_name + "-snapshot"
    end

    def lvm_snap_mount
      "/mnt/ebssense-lvmsnap#{@backupmeta.id}"
    end

    def letters_attached?(letters)
      letters.each do |letter|
        if target.block_device_mappings.keys.include?("/dev/sd#{letter}")
          return true
        else
          return false
        end
      end
    end
      
  end
end
