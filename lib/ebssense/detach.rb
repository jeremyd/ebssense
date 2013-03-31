require 'ebssense/lvm_aws_helper.rb'
require 'ebssense/run_cmd_helper.rb'

module Ebssense
  class Detach
    include Ebssense::LvmAwsHelper
    include Ebssense::RunCmdHelper

    def initialize(opts)
      @options = opts
      init_helper
      
      @backupmeta = Backupmeta.first(:name => opts[:name])
# TODO: find the attached volset in the db?
      unless @backupmeta
        info "FATAL: could not find backup metadata for #{opts[:name]} in the database. Aborting."
        exit 1 unless @options[:device_letters]
      end
      self
    end

    def detach_volumes(delete=false)
      this_volset = @backupmeta.volsets.first(:attached => true)
      info "WARNING: could not find an attached volset in the database!" unless this_volset
      info "WARNING: one or more volumes is not currently attached." unless letters_attached?(this_volset.device_letters)
      run_cmd("umount #{lvm_device_name}", true)
# lvm thinks the device is busy, try sleeping to give it time to settle
      sleep 5
      run_cmd("lvchange -an #{lvm_device_name}", true)
      detachments = []
      this_volset.device_letters.each do |suffix|
        volume_attachment = target.block_device_mappings["/dev/sd#{suffix}"]
        detachments << volume_attachment.volume
        volume_attachment.delete(:force => true)
      end
      detachments.each do |vol|
        info "waiting for #{vol.id} to be detached."
        sleep 1 until vol.status == :available
        this_volset.attached = false
        if delete
          info "deleting volume #{vol.id}"
          vol.delete
        end
      end
      if delete
        this_volset.destroy
      else
        this_volset.attached = false
        this_volset.save
      end
    end
  end

end
