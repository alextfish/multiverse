# == Schema Information
# Schema version: 20100926114339
#
# Table name: old_cards
#
#  id          :integer         not null, primary key
#  card_id     :integer
#  name        :string(255)
#  cardset_id  :integer
#  colour      :string(255)
#  rarity      :string(255)
#  cost        :string(255)
#  supertype   :string(255)
#  cardtype    :string(255)
#  subtype     :string(255)
#  rulestext   :text
#  flavourtext :text
#  power       :integer
#  toughness   :integer
#  posttime    :datetime
#  created_at  :datetime
#  updated_at  :datetime
#

class Mechanic < ActiveRecord::Base
  belongs_to :cardset 
  validates :name, :presence => true
  validates :codename, :presence => true
  validates_inclusion_of :parameters, :in => (0..2)
  
  attr_accessor :regexps
  def regexps
    if attributes[:regexps].nil?
      sep = " "                    # "|"
      src_start = "\\[#{self.codename}"
      one_param = "([^\\]]*)"
      case self.parameters 
        when 0:
          src_main = src_start
          target = self.name 
       when 1:
          src_main = src_start + sep + one_param
          target = self.name + ' \\1'
       when 2:
          src_main = src_start + sep + one_param + sep + one_param
          target = self.name + ' \\1 &ndash; \\2'
      end
      # Rails.logger.info "Compiling regexp from " + src_main + "\\(\\)\\]"
      src_no_reminder =  Regexp.new(src_main + "\\(\\)\\]")
      src_with_reminder =  Regexp.new(src_main + "\\]")
      target_no_reminder = target 
      target_with_reminder = target + (self.reminder.blank? ? "" : " (#{self.reminder})")
      attributes[:regexps] = [src_no_reminder, src_with_reminder, target_no_reminder, target_with_reminder]
    else
      attributes[:regexps]
    end
  end
end
