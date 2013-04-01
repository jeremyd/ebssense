require 'ebssense/lvm_aws_helper.rb'
require 'ebssense/run_cmd_helper.rb'

module Ebssense
  class Restore
    include Ebssense::LvmAwsHelper
    include Ebssense::RunCmdHelper
    include Ebssense::TagSync

    def initialize(opts)
      @options = opts
      init_helper(@options)
      @backupmeta = Backupmeta.first(:name => opts[:name])
    end

    def run
      # Attach the latest snapset as volumes.
      latest_snapset = @backupmeta.snapsets.first(:order => [ :started_at.desc ])
      if letters_attached?(latest_snapset.device_letters)
        info "FATAL: the device letters are already in use"
        exit 1
      end
      new_volset = Volset.create
      attachments = []
 
      latest_snapset.snapshots.each do |snapshot|
        ec2vol = @ec2.volumes.create(:size => @backupmeta.size_vol,
                         :availability_zone => target.availability_zone,
                         :snapshot_id => snapshot.id)
        attachment = ec2vol.attach_to(target, "/dev/sd#{snapshot.device_letter}")
        new_volset.volumes << Volume.create(:id => ec2vol.id, :device_letter => snapshot.device_letter)
        attachments << attachment
      end
      @backupmeta.volsets << new_volset
      attachments.each do |attachment|
        info "waiting for attachment.."
        sleep 3 until attachment.status != :attaching
# TODO detect failure to attach and timeout also
      end
      @backupmeta.volsets.all.each do |vs|
        vs.attached = false
        vs.save
      end
      new_volset.attached = true 
      new_volset.save

      # run the LVM restore
      run_cmd("mkdir -p #{lvm_snap_mount}")
      run_cmd("pvscan")
      run_cmd("lvchange -ay #{lvm_device_name}")
      run_cmd("mkdir -p #{@backupmeta.mount_point}")
      run_cmd("mount -o noatime #{lvm_device_name} #{@backupmeta.mount_point}")
      run_cmd("mkdir -p #{lvm_snap_mount}")
      run_cmd("mount -o nouuid #{lvm_snapshot_device} #{lvm_snap_mount}")
      run_cmd("mount -o remount,ro,nouuid #{lvm_snapshot_device} #{lvm_snap_mount}")

      run_cmd("rsync -a #{lvm_snap_mount}/ #{@backupmeta.mount_point}/")
      run_cmd("umount -l #{lvm_snap_mount}", true)

      sync_to_tags(new_volset)

      info "Restore complete!"
    end
  end
end
