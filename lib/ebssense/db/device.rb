class Device
  include DataMapper::Resource
  property :id, Serial
  property :letter, String
  belongs_to :backupmeta
end
