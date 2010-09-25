class User < ActiveRecord::Base
  has_many :cardsets
  has_many :comments
end
