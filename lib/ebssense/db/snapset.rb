class Snapset
  include DataMapper::Resource
  property :id, Serial
  property :status, String
  property :started_at, String, :default => ""
  belongs_to :backupmeta
  has n, :snapshots

  def device_letters
    snapshots.map { |m| m.device_letter }
  end
end
