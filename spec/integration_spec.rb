

# non-destructive migrate
#DataMapper.auto_upgrade!

# destructive migrate
DataMapper.auto_migrate!

describe "Ebssense::Build" do
  require 'ebssense/build'
  
  if ENV['EBSSENSE_TESTING_NAME']
    @@name = ENV['EBSSENSE_TESTING_NAME'] 
  end
  @@name ||= "@@nametesting"
  context "with no volumes attached" do
    it "builds a fresh stripe" do
      
      options = {
        :name=>@@name, 
        :lvm_device_name => "lvol-test",
        :lvm_volume_group => "vg-test",
        :num_vol=>3, 
        :size_vol=>6, 
        :mount_point=>"/mnt/TESTING-ebssense-#{@@name}", 
        :device_letters=>["s", "t", "u"] }

      new_ebs = Ebssense::Build.new(options)
      new_ebs.create_fresh_volumes_attach
      sleep 2
      # some assertions here like ..?k
    end
  end
  context "with the volumes attached" do
    it "backs up the volumes 3 times" do
      require 'ebssense/backup'
      options = { :name => @@name }
      3.times do
        new_bak = Ebssense::Backup.new(options)
        new_bak.run
        sleep 2
      end
    end

    it "detaches and deletes" do
      require 'ebssense/detach'
      options = { :name => @@name, :delete => true }

      detach_cmd = Ebssense::Detach.new(options)
      detach_cmd.detach_volumes(options[:delete])
      sleep 2
    end

    it "restores the latest backup" do
      require 'ebssense/restore'
      options = { :name => @@name }
      new_restore = Ebssense::Restore.new(options)
      new_restore.run
      sleep 2
    end

    it "cleans up one backup" do
      require 'ebssense/clean'
      options = { :name => @@name, :keep => 2 }
        
      backupmeta = Backupmeta.first(:name => options[:name])
      latest_snapset = backupmeta.snapsets.first(:order => [ :started_at.desc ])
      cleanup = Ebssense::Clean.new(options)
      cleanup.run

      # Specified keep=2
      backupmeta.snapsets.size.should == 2

      #expect {
      #}.to change(Backupmeta.first(:name => options[:name]).snapsets, :size).by_at_least(1)

      latest_snapset.should == backupmeta.snapsets.first(:order => [ :started_at.desc ])

    end

    it "detaches and deletes a second time" do
      require 'ebssense/detach'
      options = { :name => @@name, :delete => true }

      detach_cmd = Ebssense::Detach.new(options)
      detach_cmd.detach_volumes(options[:delete])
      sleep 2
    end
     
  end
end
