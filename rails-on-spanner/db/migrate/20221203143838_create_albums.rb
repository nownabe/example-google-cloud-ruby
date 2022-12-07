class CreateAlbums < ActiveRecord::Migration[7.0]
  def change
    create_table :albums, id: false do |t|
      t.interleave_in :singers

      t.parent_key :singer_id
      t.primary_key :album_id

      t.string :title
      t.timestamps
    end
  end
end
