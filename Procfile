# web: bundle exec rails server thin -p $PORT -e $RACK_ENV
web: bundle exec unicorn -p $PORT -E $RACK_ENV -c config/unicorn.rb
