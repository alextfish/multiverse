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
      when :cardset_create:       1
      when :card_create:          2
      when :card_edit:            3
      when :comment_card:         4
      when :details_page_create:  5
      when :details_page_edit:    6
      when :comment_details_page: 7
      when :comment_cardset:      8
      when :cardset_options:      9
      when :cardset_delete:      10
      when :card_delete:         11
      when :details_page_delete: 12
      when :comment_delete:      13
      when :mechanic_create:     14
      when :mechanic_edit:       15
      when :mechanic_delete:     16
      when :cardset_import:      17
      when :comment_edit:        18

      else
        raise "Unknown log kind specified: #{sym}"
    end
  end
  def past_tense_verb(specific)
    case self.kind
      when Log.kind(:cardset_create):
        specific ? "created the cardset " : "created a cardset"
      when Log.kind(:cardset_delete):
        specific ? "deleted the cardset " : "created a cardset"
      when Log.kind(:cardset_options):
        specific ? "changed the cardset options for " : "changed a cardset's options"
      when Log.kind(:card_create):
        specific ? "created the card " : "created a card"
      when Log.kind(:card_edit):
        specific ? "edited " : "edited a card"
      when Log.kind(:card_delete):
        specific ? "deleted a card from " : "deleted a card"
      when Log.kind(:comment_card):
        specific ? "commented on " : "commented on a card"
      when Log.kind(:comment_details_page):
        specific ? "commented on the details page " : "commented on a details page"
      when Log.kind(:comment_cardset):
        specific ? "commented on the cardset " : "commented on a cardset"
      when Log.kind(:comment_delete):
        specific ? "deleted a comment on " : "deleted a comment"
      when Log.kind(:comment_edit):
        specific ? "edited a comment on " : "edited a comment"
      when Log.kind(:details_page_create):
        specific ? "created the details page " : "created a details page"
      when Log.kind(:details_page_edit):
        specific ? "edited the details page " : "edited a details page"
      when Log.kind(:details_page_delete):
        specific ? "deleted a details page in " : "deleted a details page"
      when Log.kind(:mechanic_create):
        specific ? "created a mechanic in " : "created a mechanic"
      when Log.kind(:mechanic_edit):
        specific ? "edited a mechanic in " : "edited a mechanic"
      when Log.kind(:mechanic_delete):
        specific ? "deleted a mechanic in " : "deleted a mechanic"
      when Log.kind(:cardset_import):
        specific ? "imported cards (#{self.text}) into " : "imported cards (#{self.text})"
      else
        raise "Unknown log kind #{self.kind} found in log #{self.id}"
    end
  end
  
  def comment?
    case self.kind
      when Log.kind(:comment_card), Log.kind(:comment_details_page), Log.kind(:comment_cardset), Log.kind(:comment_edit):
        true
      when Log.kind(:comment_delete):
        false # because there's no comment to link to
      else
        false
    end
  end
  
  def return_object
    # All find calls are find_by_id: this may return nil, 
    # e.g. for the log for creating a card that was later deleted
    case self.kind
      # cardsets
      when Log.kind(:cardset_create), Log.kind(:cardset_options), Log.kind(:cardset_import):
        obj = Cardset.find_by_id(self.object_id)
        return cardset
      # cards
      when Log.kind(:card_create), Log.kind(:card_edit):
        card = Card.find_by_id(self.object_id)
        return card
      # details pages
      when Log.kind(:details_page_create), Log.kind(:details_page_edit):
        dp = DetailsPage.find_by_id(self.object_id)
        return dp
      # mechanics
      when Log.kind(:mechanic_create), Log.kind(:mechanic_edit):
        mech = Mechanic.find_by_id(self.object_id)
        return mech
      # For deleted objects, just return the parent cardset
      when Log.kind(:mechanic_delete), Log.kind(:card_delete), Log.kind(:details_page_delete):
        cardset = Cardset.find_by_id(self.object_id)
        return cardset
      # Comments: complicated by the way I didn't originally store the id of the comment itself
      when Log.kind(:comment_cardset):
        comment = Comment.find_by_id(self.object_id)
        if comment && comment.cardset && comment.cardset == self.cardset
          # We have a new-style link with a comment id: give the comment
          return comment
        else
          # We have an old-style link with just the cardset id: give the cardset
          cardset = Cardset.find_by_id(self.object_id)
          return cardset
        end
      when Log.kind(:comment_card):
        comment = Comment.find_by_id(self.object_id)
        if comment && comment.card && comment.card.cardset == self.cardset
          # We have a new-style link with a comment id: give the comment
          return comment
        else
          # We have an old-style link with just the card id: give the card
          card = Card.find_by_id(self.object_id)
          if card && card.cardset == self.cardset
            return card
          else
            # New-style comment on a comment that's since been deleted
            return nil
          end
        end
      # Deleted comment may have been on a card, or maybe not
      when Log.kind(:comment_delete):
        card = Card.find_by_id(self.object_id)
        if card && card.cardset == self.cardset
          return card
        else
          return self.cardset
        end
      # For edited comments and details page comments
      when Log.kind(:comment_edit), Log.kind(:comment_details_page):
        comment = Comment.find_by_id(self.object_id)
        return comment
      else
        raise "Don't know how to get the object from logs of kind #{self.kind} such as log #{self.id}"
    end
  end
  
  # See also application_helper/link_to_log_object()
end
