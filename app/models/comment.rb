# == Schema Information
# Schema version: 20100930004247
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  card_id    :integer
#  user       :text
#  posttime   :datetime
#  comment    :text
#  status     :integer
#  created_at :datetime
#  updated_at :datetime
#

class Comment < ActiveRecord::Base
  belongs_to :card
  #belongs_to :user

#   validates_presence_of :name
#   validates_length_of :name, :within => 2..20
  validates_presence_of :comment

  NORMAL = 0
  UNADDRESSED = 1
  HIGHLIGHTED = 2
end
