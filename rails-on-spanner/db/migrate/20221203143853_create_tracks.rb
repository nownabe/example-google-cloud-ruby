class CreateTracks < ActiveRecord::Migration[7.0]
  def change
    create_table :tracks, id: false do |t|
      t.interleave_in :albums, :cascade

      t.parent_key :singer_id
      t.parent_key :album_id
      t.primary_key :track_id

      t.string :title

      t.timestamps
    end
  end
end
