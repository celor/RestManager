json.array!(@tracks) do |track|
  json.extract! track, :id, :duration, :name, :position
  json.url track_url(track, format: :json)
end
