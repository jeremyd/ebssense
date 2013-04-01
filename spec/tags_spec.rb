DataMapper.auto_migrate!

require 'ebssense/tag_sync'
require 'pry'

class TagSpecHelper
  include Ebssense::TagSync
  include Ebssense::RunCmdHelper
  
  def initialize
    @ec2 = AWS::EC2.new()
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
    self
  end

end

describe "Ebssense::TagSync" do
  context "as a mixin" do
    it "syncs the sqlite.db with the tags" do
      @tag = ENV['EBSSENSE_TESTING_NAME']
      @tag ||= "tagtimetestingebssense123"
      tsp = TagSpecHelper.new
      tsp.sync_from_tags(@tag)
      Backupmeta.first(:name => @tag).should be
      Backupmeta.first(:name => @tag).size_vol.should be
      Backupmeta.first(:name => @tag).volsets.first.device_letters.first.should be
      Backupmeta.first(:name => @tag).volsets.first.should be
      Backupmeta.first(:name => @tag).snapsets.first.should be
      Backupmeta.first(:name => @tag).snapsets.first.device_letters.first.should be
    end
  end
end
