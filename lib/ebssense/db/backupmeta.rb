class Backupmeta
  include DataMapper::Resource
  property :id, Serial
  property :mount_point, String
  property :name, String, :unique => true
  property :size_vol, Integer
  has n, :volsets
  has n, :snapsets

  validates_uniqueness_of :name

  def device_letters
    letter_guess = nil
    if va = volsets.first(:attached => true)
      letter_guess = va.device_letters
    elsif v = volsets.last
      letter_guess = v.device_letters
    elsif s = snapsets.last
      letter_guess = s.device_letters
    end
    letter_guess
  end
end
