class CreateSingers < ActiveRecord::Migration[7.0]
  def change
    create_table :singers, id: false do |t|
      t.primary_key :singer_id
      t.string :name

      t.timestamps
    end
  end
end
