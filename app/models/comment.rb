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

  def addressed?
    status != UNADDRESSED
  end
  def unaddressed?
    status == UNADDRESSED
  end
  def highlighted?
    status == HIGHLIGHTED
  end
  def admin_status_string
    case self.status
      when UNADDRESSED: "unaddressed"
      when HIGHLIGHTED: "highlighted"
      else              "normal"
    end
  end
  def public_status_string
    case self.status
      when HIGHLIGHTED: "highlighted"
      else              "normal"
    end
  end
end
