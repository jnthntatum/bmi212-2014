# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

u = User.create(first_name: 'Jon', last_name: 'Tatum', email: 'jdtatum@stanford.edu', password: 'password')
u.save!

u = User.create(first_name: 'Kimberly', last_name: 'McManus', email: 'kfm@stanford.edu', password: 'password')
u.save!

u = User.create(first_name: 'Rachel', last_name: 'Goldfeder', email: 'rlgoldfeder@gmail.com', password: 'password')
u.save!

u = User.create(first_name: 'Winn', last_name: 'Haynes', email: 'hayneswa@stanford.edu', password: 'password')
u.save!

u = User.create(first_name: 'Emily', last_name: 'Doughty', email: 'edoughty@stanford.edu', password: 'password')
u.save!