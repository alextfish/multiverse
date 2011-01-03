# == Schema Information
# Schema version: 20110101155400
#
# Table name: logs
#
#  id         :integer         not null, primary key
#  cardset_id :integer
#  datestamp  :datetime
#  kind       :integer
#  user_id    :integer
#  object_id  :integer
#  text       :text
#  created_at :datetime
#  updated_at :datetime
#

# Table name: logs

class Log < ActiveRecord::Base
  belongs_to :cardset
  belongs_to :user
  validates_inclusion_of :kind, :in => (1..18)
  default_scope :order => 'logs.datestamp DESC'
  
  def Log.kind(sym)
    case sym
      when :cardset_create: 1
      when :card_create: 2
      when :card_edit: 3
      when :comment_card: 4
      when :details_page_create: 5
      when :details_page_edit: 6
      when :comment_details_page: 7
      when :comment_cardset: 8
      when :cardset_options: 9
      when :cardset_delete: 10
      when :card_delete: 11
      when :details_page_delete: 12
      when :comment_delete: 13
      when :mechanic_create: 14
      when :mechanic_edit: 15
      when :mechanic_delete: 16
      when :cardset_import: 17
      when :comment_edit: 18

      else
        raise "Unknown log kind specified: #{sym}"
    end
  end
  def past_tense_verb
    case self.kind
      when Log.kind(:cardset_create):
        "created the cardset"
      when Log.kind(:cardset_delete):
        "deleted the cardset"
      when Log.kind(:cardset_options):
        "changed the cardset options for"
      when Log.kind(:card_create):
        "created the card"
      when Log.kind(:card_edit):
        "edited"
      when Log.kind(:card_delete):
        "deleted a card"
      when Log.kind(:comment_card):
        "commented on"
      when Log.kind(:comment_details_page):
        "commented on the details page"
      when Log.kind(:comment_cardset):
        "commented on the cardset"
      when Log.kind(:comment_delete):
        "deleted a comment"
      when Log.kind(:comment_edit):
        "edited a comment on"
      when Log.kind(:details_page_create):
        "created the details page"
      when Log.kind(:details_page_edit):
        "edited the details page"
      when Log.kind(:details_page_delete):
        "deleted a details page in"
      when Log.kind(:mechanic_create):
        "created a mechanic in"
      when Log.kind(:mechanic_edit):
        "edited a mechanic in"
      when Log.kind(:mechanic_delete):
        "deleted a mechanic in"
      when Log.kind(:cardset_import):
        "imported cards (#{self.text}) into"
      else
        raise "Unknown log kind #{self.kind} found in log #{self.id}"
    end
  end
  
  # See also application_helper/link_to_log_object()
end
