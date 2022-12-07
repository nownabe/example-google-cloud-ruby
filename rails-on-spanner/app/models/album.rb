class Album < ApplicationRecord
  self.primary_keys = [:singer_id, :album_id]

  belongs_to :singer, foreign_key: :singer_id
  has_many :tracks, foreign_key: [:singer_id, :album_id]
end
