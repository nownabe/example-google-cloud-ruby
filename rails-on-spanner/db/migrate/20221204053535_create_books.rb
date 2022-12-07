class CreateBooks < ActiveRecord::Migration[7.0]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.string :tags, array: true, null: false, default: []
      t.string :ratings, array: true, null: false, default: []

      t.timestamps
    end
  end
end
