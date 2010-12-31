# == Schema Information
# Schema version: 20101215230231
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  card_id    :integer
#  user_name  :text
#  posttime   :datetime
#  body       :text
#  status     :integer
#  created_at :datetime
#  updated_at :datetime
#  cardset_id :integer
#  user_id    :integer
#

class Comment < ActiveRecord::Base
  belongs_to :card
  belongs_to :cardset
  belongs_to :user

  default_scope order("comments.created_at")

  # Validate there's either a user name or a user ID
  attr_accessor :by_signed_in_user
  #validates_length_of :user_name, :within => 1..40, :unless => :by_signed_in_user
  validates_presence_of :body
  validate :comment_validation, :on => :create
  def comment_validation
    if body.blank?
      errors.add(:body, " cannot be empty.")
    end
    if user_id.nil? && user_name.blank?
      errors.add(:user_name, " cannot be empty.")
    elsif user_id.nil? && !User.find_by_name(user_name).blank?
      errors.add(:user_name, " #{user_name} is the name of an existing Multiverse user. Please choose a different name.")
    end
  end

  # Class methods
  def self.status
    { :normal => 0,
      :unaddressed => 1,
      :highlighted => 2
    }
  end
  def self.DEFAULT_USER_NAME
    "Visitor"
  end


  # Instance methods
  def set_default_status!
    self.status = (get_cardset.configuration.default_comment_state == "unaddressed") ? Comment.status[:unaddressed] : Comment.status[:normal]
  end

  def get_cardset
    cardset || card.cardset
  end
  def parent
    cardset || card
  end
  def display_user
    user ? user.name : user_name
  end
  def recency  # For a comment, its order in recency is when it was posted; we ignore updates to its status
    created_at
  end

  def addressed?
    status != Comment.status[:unaddressed]
  end
  def unaddressed?
    status == Comment.status[:unaddressed]
  end
  def highlighted?
    status == Comment.status[:highlighted]
  end
  def admin_status_string
    if self.status == Comment.status[:unaddressed] && get_cardset.configuration.use_addressing
      "unaddressed"
    elsif self.status == Comment.status[:highlighted] && get_cardset.configuration.use_highlighting
      "highlighted"
    else
      "normal"
    end
  end
  def public_status_string
    if self.status == Comment.status[:highlighted] && get_cardset.configuration.use_highlighting
      "highlighted"
    else
      "normal"
    end
  end
end
