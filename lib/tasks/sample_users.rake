namespace :db do
  desc "Fill database with sample data"
  task :populate => :environment do
    Rake::Task['db:reset'].invoke
    alex = User.create!(:name => "Alex Churchill",
                 :email => "alex.churchill@cantab.net",
                 :password => "fish",
                 :password_confirmation => "fish")
    alex.toggle!(:admin)
    29.times do |n|
      name  = (n+?A).chr + "ob User"
      email = "example-#{n+1}@railstutorial.org"
      password  = "password"
      User.create!(:name => name,
                   :email => email,
                   :password => password,
                   :password_confirmation => password)
    end

    sienira = Cardset.create!(:name => "Sienira's Facets",
                :user_id => alex.id,
                :description => "A set all about card types.")
  end
end
