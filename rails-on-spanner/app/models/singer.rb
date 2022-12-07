class Singer < ApplicationRecord
  has_many :albums, foreign_key: :singer_id
  has_many :tracks, foreign_key: :singer_id
end
