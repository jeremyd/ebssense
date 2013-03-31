module Ebssense
  class Build
    include Ebssense::LvmAwsHelper
    include Ebssense::RunCmdHelper
    include Ebssense::TagSync

    def initialize(opts)
      @options = opts
      init_helper
      
      @options[:device_letters].each do |device|
        raise "FATAL: /dev/sd#{device} is already attached." if target.block_device_mappings.keys.include?("/dev/sd#{device}")
      end
      @backupmeta = Backupmeta.create(:name => opts[:name], :mount_point => opts[:mount_point], :size_vol => opts[:size_vol])
      @backupmeta.save
      self
    end

    def create_fresh_volumes_attach
      new_volset = Volset.create(:attached => false)
      
      attachments = []
      # Create the volumes and their attachment requests
      @options[:device_letters].each do |device|
        info "Creating new EBS volume of size #{@options[:size_vol]} in #{target.availability_zone}.."
        img_vol = @ec2.volumes.create(:size => @options[:size_vol],
             :availability_zone => target.availability_zone)
        new_vol = Volume.create(:id => img_vol.id, :device_letter => device)
        new_volset.volumes << new_vol
        new_volset.save
        info "Attaching volume #{img_vol.id} to target.."
        attachment = img_vol.attach_to(target, "/dev/sd#{device}")
        attachments << attachment
      end
      @backupmeta.volsets << new_volset
      @backupmeta.save
      # Wait for all volumes to attach
      sleep 1
      attachments.each do |a|
        info "Waiting for attachment.."
  # TODO: timeout
        sleep 1 until a.status != :attaching
      end
      local_device_names.each do |dname|
        wait_for_local_attach(dname)
      end
      @backupmeta.volsets.all.each do |vs|
        vs.attached = false
        vs.save
      end
      new_volset.attached = true
      new_volset.save
      sync_to_tags(new_volset)
      # Begin LVM + XFS
      # pvcreate
      # Create the volumes and their attachment requests
      @options[:device_letters].each do |device|
        run_cmd("pvcreate -fy /dev/xvd#{device}")
      end
      # vgcreate
      run_cmd("vgcreate #{volume_group_name} #{local_device_names.join(" ")}")
      # lvcreate
      run_cmd("lvcreate #{volume_group_name} -n #{lvm_volume_name} -i #{@options[:num_vol]} -I 256 -l 80%VG")
      # format
      run_cmd("mkfs.xfs #{lvm_device_name}")
      # mount
      run_cmd("mkdir -p #{@options[:mount_point]}")
      run_cmd("mount -o noatime #{lvm_device_name} #{@options[:mount_point]}")
      # add to fstab
      fstab = IO.read("/etc/fstab")
      unless fstab.include?(lvm_device_name)
        info "creating entry in fstab"
        FileUtils.cp("/etc/fstab", "/etc/fstab.bak")
        File.open("/etc/fstab", "a") do |f| 
          f.puts("#{lvm_device_name} #{@options[:mount_point]} xfs defaults,noatime,nobootwait 0 0")
        end
      end
    end
  end
end
