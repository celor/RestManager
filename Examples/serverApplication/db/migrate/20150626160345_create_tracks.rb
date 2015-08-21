class CreateTracks < ActiveRecord::Migration
  def change
    create_table :tracks do |t|
      t.float :duration
      t.string :name
      t.integer :position

      t.timestamps null: false
    end
  end
end
