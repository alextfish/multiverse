# == Schema Information
# Schema version: 20110101155400
#
# Table name: mechanics
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  cardset_id  :integer
#  codename    :string(255)
#  reminder    :text
#  parameters  :integer
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#

class Mechanic < ActiveRecord::Base
  belongs_to :cardset, touch: true
  attr_protected :cardset_id
  
  validates :name, :presence => true
  validates :codename, :presence => true
  validates_inclusion_of :parameters, :in => (0..2)
  
  attr_accessor :regexps
  def Mechanic.one_param
    "([^\\]]*)"
  end
  def regexps
    if attributes[:regexps].nil?
      sep = " "                    # "|"
      src_start = "\\[#{self.codename}"
      case self.parameters 
        when 0
          src_main = src_start
          target = self.name 
       when 1
          src_main = src_start + sep + Mechanic.one_param
          target = self.name + ' \\1'
       when 2
          src_main = src_start + sep + Mechanic.one_param + sep + Mechanic.one_param
          target = self.name + ' \\1 - \\2'
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
