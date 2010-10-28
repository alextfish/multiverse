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

  default_scope order("comments.created_at")

#   validates_presence_of :name
  validates_length_of :user, :within => 1..40
  validates_presence_of :comment

  def recency  # For a comment, its order in recency is when it was posted; we ignore updates to its statu
    created_at
  end

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
