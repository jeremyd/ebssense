require 'digest/sha1'
module Ebssense
  module TagSync
    # accepts a volset or snapset
    def sync_to_tags(theset)
      if theset.is_a?(Volset)
        unique_id = Digest::SHA1.hexdigest(theset.volumes.map {|m| m.id}.join(" "))
        theset.volumes.each do |v|
          ec2vol = @ec2.volumes[v.id]
          ec2vol.add_tag("Name", :value => theset.backupmeta.name)
          ec2vol.add_tag("device_letter", :value => v.device_letter)
          ec2vol.add_tag("mount_point", :value => theset.backupmeta.mount_point)
          ec2vol.add_tag("volset_uuid", :value => unique_id)
        end
      elsif theset.is_a?(Snapset)
        unique_id = Digest::SHA1.hexdigest(theset.snapshots.map {|m| m.id}.join(" "))
        theset.snapshots.each do |s|
          ec2snap = @ec2.snapshots[s.id]
          ec2snap.add_tag("Name", :value => theset.backupmeta.name)
          ec2snap.add_tag("device_letter", :value => s.device_letter)
          ec2snap.add_tag("mount_point", :value => theset.backupmeta.mount_point)
          ec2snap.add_tag("snapset_uuid", :value => unique_id)
          ec2snap.add_tag("status", :value => theset.status)
        end
      else
        info("Not a supported tag sync type #{theset.class}")
        exit 1
      end
    end

    def all_names
    # TODO: possibly more confirmation than just that they have a Name tag?
      taglist = []
      @ec2.snapshots.tagged("Name").each do |snap|
        taglist << snap.tags.to_h["Name"]
      end
      @ec2.volumes.tagged("Name").each do |vol|
        taglist << vol.tags.to_h["Name"]
      end
      taglist.uniq
    end

# TODO also get started_at for each *set
    def sync_from_tags(name)
      # First we'll do volumes
      found_volumes = @ec2.volumes.tagged("Name").tagged_values(name)
      fv_count = found_volumes.count
      info "Found #{fv_count} volumes tagged with #{name}"
# TODO: verify this against the other volumes?
      new_backupmeta = nil
      if fv_count > 0
        new_volsets = {}
        mount_point = nil
        size_vol = nil
        found_volumes.each do |vol|
          thetags = vol.tags.to_h
          unless new_volsets.has_key?(thetags["volset_uuid"])
            new_volsets[thetags["volset_uuid"]] = Volset.create()
          end
          new_volsets[thetags["volset_uuid"]].volumes << Volume.create(:id => vol.id, :device_letter => thetags["device_letter"])
# these tags can be found on any volume
          mount_point = thetags["mount_point"]
          size_vol = vol.size
        end
        new_backupmeta = Backupmeta.new(:name => name, :mount_point => mount_point, :size_vol => size_vol)
        new_volsets.each do |_,v|
          new_backupmeta.volsets << v
          v.save
        end
        new_backupmeta.save
      end
      # Then we'll do snaps
      found_snapshots = @ec2.snapshots.tagged("Name").tagged_values(name)
      fs_count = found_snapshots.count
      info "Found #{fs_count} snapshots tagged with #{name}"
      if fs_count > 0
        new_snapsets = {}
        mount_point = nil
        size_vol = nil
        found_snapshots.each do |snap|
          thetags = snap.tags.to_h
          unless new_snapsets.has_key?(thetags["snapset_uuid"])
            new_snapsets[thetags["snapset_uuid"]] = Snapset.create(:started_at => snap.start_time.to_s)
          end
          new_snapsets[thetags["snapset_uuid"]].snapshots << Snapshot.create(:id => snap.id, :device_letter => thetags["device_letter"])
          size_vol = snap.volume_size
          mount_point = thetags["mount_point"]
        end
# Create a new backupmeta if it wasn't created in the snapsync
        unless new_backupmeta
          new_backupmeta = Backupmeta.new(:name => name, :mount_point => mount_point, :size_vol => size_vol)
        end
        new_snapsets.each do |_,v|
          new_backupmeta.snapsets << v
          v.save
        end
        new_backupmeta.save
      end
    end

  end
end
