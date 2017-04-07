# The has_many association gives this a bunch of methods:
# cards(force_reload = false)
# cards<<(object, …)   / cards.push(card)
# cards.delete(object, …)
# cards=objects
# card_ids
# card_ids=ids
# cards.clear   - blanks the decklist, doesn't delete cards
# cards.empty?
# cards.size
# cards.find(…)
# cards.where(…)
# cards.exists?(…)
# cards.build(attributes = {}, …)
# cards.create(attributes = {})

class Decklist < ActiveRecord::Base
  belongs_to :user
  belongs_to :cardset
  # http://stackoverflow.com/questions/16569994/
  has_many :cards, -> { uniq }, :through => :deck_cards
  has_many :deck_cards, :dependent => :destroy  # to get at the counts and sections
  has_many :deck_wizards_cards, :dependent => :destroy  # to get at the counts and sections
  attr_protected :cardset_id, :user_id
  
  PUBLISHED = 4
  VIEWABLE = 8
  EDITABLE = 16
  HIGHEST_STATUS = 31
  DEFAULT_STATUS = 0
  VISIBILITY_VALUES = [["Private to me", 0], ["Visible to all", 8], ["Editable by all", 24]]
  
  validates_inclusion_of :status, :in => (0..HIGHEST_STATUS)
  
  def active?
    self.active
  end
  def published?
    (status & PUBLISHED) > 0
  end
  def editable?
    (status & EDITABLE) > 0
  end
  def viewable?
    (status & VIEWABLE) > 0
  end
  def sections
    all_secs = deck_cards.map{ |dc| dc.section } + deck_wizards_cards.map{ |dc| dc.section }
    # Now add Sideboard and Maybeboard, at the *end*
    if (!published? || all_secs.include?("Maybeboard"))
      all_secs = all_secs - ["Sideboard", "Maybeboard"]
      all_secs.concat(["Sideboard", "Maybeboard"])
    else
      all_secs = all_secs - ["Sideboard"]
      all_secs.concat(["Sideboard"])
    end
    all_secs.uniq
  end
  def Decklist.basic_land_section
    "Land"
  end
  def Decklist.extra_classes(section)
    if section == "Sideboard"
      "sideboard"
    elsif section == "Maybeboard"
      "maybeboard"
    else
      ""
    end
  end
  def num_cards
    # Shows in the permanent display, so don't calculate all the stats for this
    deck_cards.map(&:count).sum + deck_wizards_cards.map(&:count).sum
  end
  
  def add_card(card, count = 1, section = "")
    if (deck_card = deck_cards.find_by(card_id: card.id)).present?
      deck_card.count += count
      deck_card.save!
    else
      deck_card = deck_cards.create(card_id: card.id, count: count, section: section)
    end
    reset_stats
    return deck_card
  end
  def set_card_count(card, num)
    deck_card = deck_cards.find_by(card_id: card.id)
    if num <= 0
      deck_card.destroy
    else
      deck_card.count = num
      deck_card.save!
    end
    reset_stats
  end
  def add_wizards_card(wiz_card, count = 1, section = "")
    # wiz_card may be a gatherer ID or a card name
    if (isnum = (wiz_card.is_a? Numeric))
      dwc = deck_wizards_cards.find_by(gatherer_id: wiz_card)
    else
      dwc = deck_wizards_cards.find_by(name: wiz_card)
    end
    if dwc.present?
      dwc.count += count
      dwc.save!
    else
      gatherer_id = (isnum ? wiz_card : 0)
      name = (isnum ? "" : wiz_card)
      dwc = deck_wizards_cards.create(gatherer_id: gatherer_id, name: name, count: count, section: section)
    end
    reset_stats
    return dwc
  end
  
  #? attr_accessor :stats
  def stats
    if attributes[:stats].nil?
      # calc them
      attributes[:stats] = calculated_stats
    else
      attributes[:stats]
    end
  end
  def reset_stats
    attributes[:stats] = nil
    save!
  end
  
  def permission_message(action)
    case action
      when :comment
        verb = "comment on"
        perm = configuration.commentability
      when :view
        verb = "view"
        perm = configuration.visibility
      when :edit
        verb = "edit"
        perm = configuration.editability
      when :delete
        verb = "delete cards in"
        perm = configuration.adminability
      when :admin
        verb = "take admin actions on"
        perm = configuration.adminability
      else
        raise "Bad input to permission_message #{action}"
    end
    @@permitted_users_are[perm] + " permitted to #{verb} this cardset."
  end
  
  def Decklist.enabled?
    false # !Rails.env.production?
  end
end
