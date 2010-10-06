# == Schema Information
# Schema version: 20100926114339
#
# Table name: cardsets
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  user_id     :integer
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#

class Cardset < ActiveRecord::Base
  attr_accessible :name, :description
  belongs_to :user
  has_many :cards
  has_many :admins, :class_name => "User"
end
