
# non-destructive migrate
DataMapper.auto_upgrade!

# destructive migrate
#DataMapper.auto_migrate!


describe "Ebssense::Build" do
  context "with no volumes attached" do
    it "builds a fresh stripe" do
      
      options = {
        :name=>"anotherEBS", 
        :num_vol=>3, 
        :size_vol=>6, 
        :mount_point=>"/mnt/TESTING-ebssense-anotherEBS", 
        :device_letters=>["s", "t", "u"] }

      new_ebs = Ebssense.new(options)
      new_ebs.create_fresh_volumes_attach
      # some assertions here like ..?k
    end
  end
end
