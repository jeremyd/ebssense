class Volset
  include DataMapper::Resource
  property :id, Serial
  property :attached, Boolean

  belongs_to :backupmeta
  has n, :volumes

  def device_letters
    volumes.map { |m| m.device_letter }
  end
end
