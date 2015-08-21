class CreateAlbumsArtistsJoinTable < ActiveRecord::Migration
  def change
  	create_join_table :albums, :artists
  end
end
