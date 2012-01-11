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
  HIGHEST_LOG_KIND = 22
  def Log.HIGHEST_LOG_KIND
    HIGHEST_LOG_KIND
  end
  validates_inclusion_of :kind, :in => (1..HIGHEST_LOG_KIND)
  default_scope :order => 'logs.datestamp DESC'
  
  def Log.kind(sym)
    case sym
      when :cardset_create then       1
      when :card_create then          2
      when :card_edit then            3
      when :comment_card then         4
      when :details_page_create then  5
      when :details_page_edit then    6
      when :comment_details_page then 7
      when :comment_cardset then      8
      when :cardset_options then      9
      when :cardset_delete then      10
      when :card_delete then         11
      when :details_page_delete then 12
      when :comment_delete then      13
      when :mechanic_create then     14
      when :mechanic_edit then       15
      when :mechanic_delete then     16
      when :cardset_import then      17
      when :comment_edit then        18
      when :skeleton_generate then   19
      when :skeleton_edit then       20
      when :card_move_out then       21
      when :card_move_in then        22
      # when added new log types, update the definition of HIGHEST_LOG_KIND above
      else
        raise "Unknown log kind specified: #{sym}"
    end
  end
  def Log.kinds_to_not_show(situation)
    case situation
      when :card_history
        [Log.kind(:comment_edit), Log.kind(:comment_delete), Log.kind(:card_move_out)]
      when :cardset_recent
        [Log.kind(:comment_edit)]
      else
        [Log.kind(:comment_edit)]
    end
  end
  def show_text?
    case self.kind
      when Log.kind(:card_edit) then true
      else                           false
    end
  end
  def past_tense_verb(specific)
    case self.kind
      when Log.kind(:cardset_create)
        specific ? "created the cardset " : "created a cardset"
      when Log.kind(:cardset_delete)
        specific ? "deleted the cardset " : "created a cardset"
      when Log.kind(:cardset_options)
        specific ? "changed the cardset options for " : "changed a cardset's options"
      when Log.kind(:card_create)
        specific ? "created the card " : "created a card"
      when Log.kind(:card_edit)
        specific ? "edited " : "edited a card"
      when Log.kind(:card_delete)
        specific ? "deleted a card from " : "deleted a card"
      when Log.kind(:comment_card)
        specific ? "commented on " : "commented on a card"
      when Log.kind(:comment_details_page)
        specific ? "commented on the details page " : "commented on a details page"
      when Log.kind(:comment_cardset)
        specific ? "commented on the cardset " : "commented on a cardset"
      when Log.kind(:comment_delete)
        specific ? "deleted a comment on " : "deleted a comment"
      when Log.kind(:comment_edit)
        specific ? "edited a comment on " : "edited a comment"
      when Log.kind(:details_page_create)
        specific ? "created the details page " : "created a details page"
      when Log.kind(:details_page_edit)
        specific ? "edited the details page " : "edited a details page"
      when Log.kind(:details_page_delete)
        specific ? "deleted a details page in " : "deleted a details page"
      when Log.kind(:mechanic_create)
        specific ? "created a mechanic in " : "created a mechanic"
      when Log.kind(:mechanic_edit)
        specific ? "edited a mechanic in " : "edited a mechanic"
      when Log.kind(:mechanic_delete)
        specific ? "deleted a mechanic in " : "deleted a mechanic"
      when Log.kind(:cardset_import)
        specific ? "imported cards (#{self.text}) into " : "imported cards (#{self.text})"
      when Log.kind(:skeleton_generate)
        specific ? "generated part of a set skeleton in " : "generated part of a set skeleton"
      when Log.kind(:skeleton_edit)
        specific ? "edited the set skeleton in " : "edited the set skeleton"
      when Log.kind(:card_move_out)
        specific ? ["moved the card ", " from #{self.cardset.name} into #{self.text}"] : "moved a card out"
      when Log.kind(:card_move_in)
        specific ? ["moved the card ", " from #{self.text} into #{self.cardset.name}"] : "moved a card in"
      else
        raise "Unknown log kind #{self.kind} found in log #{self.id}"
    end
  end
  
  def recency  # For a comment, its order in recency is its datestamp
    datestamp
  end
  
  def comment?
    case self.kind
      when Log.kind(:comment_card), Log.kind(:comment_details_page), Log.kind(:comment_cardset), Log.kind(:comment_edit)
        true
      when Log.kind(:comment_delete)
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
      when Log.kind(:cardset_create), Log.kind(:cardset_options), Log.kind(:cardset_import)
        cardset = Cardset.find_by_id(self.object_id)
        return cardset
      when Log.kind(:cardset_delete)
        return nil
      # cards
      when Log.kind(:card_create), Log.kind(:card_edit), Log.kind(:card_move_in), Log.kind(:card_move_out)
        card = Card.find_by_id(self.object_id)
        return card
      # details pages
      when Log.kind(:details_page_create), Log.kind(:details_page_edit)
        dp = DetailsPage.find_by_id(self.object_id)
        return dp
      # mechanics
      when Log.kind(:mechanic_create), Log.kind(:mechanic_edit)
        mech = Mechanic.find_by_id(self.object_id)
        return mech
      # skeletons
      when Log.kind(:skeleton_generate), Log.kind(:skeleton_edit)
        dp = DetailsPage.find_by_id(self.object_id)
        return dp
      # For deleted objects, just return the parent cardset
      when Log.kind(:mechanic_delete), Log.kind(:card_delete), Log.kind(:details_page_delete)
        cardset = Cardset.find_by_id(self.object_id)
        return cardset
      # Comments: complicated by the way I didn't originally store the id of the comment itself
      when Log.kind(:comment_cardset)
        comment = Comment.find_by_id(self.object_id)
        if comment && comment.cardset && comment.cardset == self.cardset
          # We have a new-style link with a comment id: give the comment
          return comment
        else
          # We have an old-style link with just the cardset id: give the cardset
          cardset = Cardset.find_by_id(self.object_id)
          return cardset
        end
      when Log.kind(:comment_card)
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
      when Log.kind(:comment_delete)
        card = Card.find_by_id(self.object_id)
        if card && card.cardset == self.cardset
          return card
        else
          return self.cardset
        end
      # For edited comments and details page comments
      when Log.kind(:comment_edit), Log.kind(:comment_details_page)
        comment = Comment.find_by_id(self.object_id)
        return comment
      else
        raise "Don't know how to get the object from logs of kind #{self.kind} such as log #{self.id}"
    end
  end
  # See also application_helper/link_to_log_object()
  
  def what_are_you
    "Log"
  end
end
