json.array!(@artists) do |artist|
  json.extract! artist, :id, :name

json.albums artist.albums do |album|
	json.(album, :id, :name, :release_date)
end
end
