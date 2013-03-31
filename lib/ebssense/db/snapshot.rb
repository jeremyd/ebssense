class Snapshot
  include DataMapper::Resource
  property :int_id, Serial
  property :id, String #The AWS id
  property :device_letter, String
  belongs_to :snapset
end
