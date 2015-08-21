# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
albums = Album.create([{name:'Let There Be Rock',release_date:'1977-08-01T00:00:00.000Z'},{name:'Highway to Hell',release_date:'1979-11-01T00:00:00.000Z'},{name:'Back in Black',release_date:'1980-08-01T00:00:00.000Z'}])
Artist.create(name:'ACDC', albums:albums)