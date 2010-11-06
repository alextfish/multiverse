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
  belongs_to :cardset
  #belongs_to :user

  default_scope order("comments.created_at")

#   validates_presence_of :name
  validates_length_of :user, :within => 1..40
  validates_presence_of :comment

  def comment_status  # also defined in application_helper :(
    { :normal => 0,
      :unaddressed => 1,
      :highlighted => 2
    }
  end

  def set_default_status!
    self.status = (get_cardset.configuration.default_comment_state == "Unaddressed") ? comment_status[:unaddressed] : comment_status[:normal]
  end

  def get_cardset
    cardset || card.cardset
  end
  def recency  # For a comment, its order in recency is when it was posted; we ignore updates to its status
    created_at
  end

  def addressed?
    status != comment_status[:unaddressed]
  end
  def unaddressed?
    status == comment_status[:unaddressed]
  end
  def highlighted?
    status == comment_status[:highlighted]
  end
  def admin_status_string
    if self.status == comment_status[:unaddressed] && self.card.cardset.configuration.use_addressing
      "unaddressed"
    elsif self.status == comment_status[:highlighted] && self.card.cardset.configuration.use_highlighting
      "highlighted"
    else
      "normal"
    end
  end
  def public_status_string
    if self.status == comment_status[:highlighted] && self.card.cardset.configuration.use_highlighting
      "highlighted"
    else
      "normal"
    end
  end
end
