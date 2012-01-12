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
  before_save :check_links
  
  # Validation and pre-save
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
  
  
  def check_links
    # "+?" = not greedy
    Rails.logger.info "Checking body for bad links"
    body.gsub!(/\(\(\((.+?)\)\)\)/) {|link_contents| fix_internal_link(link_contents, $1)}
    ############# COMMENTED OUT: the is_printed_card_name regexp
    ############# causes errors on production server!
    # body.gsub!(/\[\[\[(.+?)\]\]\]/) {|link_contents| fix_external_link(link_contents, $1)}
    Rails.logger.info "After fixing links, body is:\n#{body}"
  end

  def fix_internal_link(full_link, inside_link)
    Rails.logger.info "Checking internal link #{inside_link}"
    if inside_link =~ /^C[0-9]+$/
      # Leave it alone
      return full_link
    end
    # search cardset for that card.
    if get_cardset.is_card_name? inside_link
      # Leave it alone
      return full_link
    end
    # OK, it's bad: let's try to fix it
    possible_targets = Card.find_all_by_name inside_link
    if !possible_targets.empty?
      # Either there's one hit, [0], or
      # there's multiple, in which case we want the chronologically earliest -
      # which is also [0].
      return "(((C#{possible_targets[0].id})))"
    end
    # One more chance: it might not be an internal link at all, but a mistake for an external link.
    ############# COMMENTED OUT: the is_printed_card_name regexp
    ############# causes errors on production server!
    #if Card.is_printed_card_name? inside_link
    #  return "[[[#{inside_link}]]]"
    #end
    # Out of ideas: just return the bad link
    return full_link
  end
  
  def fix_external_link(full_link, inside_link)
    Rails.logger.info "Checking external link '#{inside_link}'"
    # search printed cards for that card
    if Card.is_printed_card_name? inside_link
      # Leave it alone
      Rails.logger.info "Found: printed"
      return full_link
    end
    # OK, let's see if it's a mistake for an internal link instead
    if inside_link =~ /^C[0-9]+$/
      # Fix syntax
      Rails.logger.info "Found: Cnnn syntax"
      return "(((#{inside_link})))"
    end
    if get_cardset.is_card_name? inside_link
      # Fix syntax
      Rails.logger.info "Found: this cardset card"
      return "(((#{inside_link})))"
    end
    # Check for a Multiverse card anywhere
    possible_targets = Card.find_all_by_name inside_link
    if !possible_targets.empty?
      # Either there's one hit, [0], or
      # there's multiple, in which case we want the chronologically earliest -
      # which is also [0].
      Rails.logger.info "Found: other cardset card"
      return "(((C#{possible_targets[0].id})))"
    end
    # Out of ideas: just return the bad link
      Rails.logger.info "Not found"
    return full_link
  end
  
  
  def anchor_name
    "comment_#{id}"
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
  def what_are_you
    "Comment"
  end
end
