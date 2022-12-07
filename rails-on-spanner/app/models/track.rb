class Track < ApplicationRecord
  self.primary_keys = [:singer_id, :album_id, :track_id]

  belongs_to :album, foreign_key: [:singer_id, :album_id]
  belongs_to :singer, foreign_key: :singer_id

  def initialize(attributes = nil)
    super
    self.singer ||= album&.singer
  end

  def album=(value)
    super
    self.singer = value&.singer
  end
end
