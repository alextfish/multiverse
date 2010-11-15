# == Schema Information
# Schema version: 20101103224310
#
# Table name: details_pages
#
#  id         :integer         not null, primary key
#  cardset_id :integer
#  title      :string(255)
#  body       :text
#  order      :integer
#  created_at :datetime
#  updated_at :datetime
#

class DetailsPage < ActiveRecord::Base
  belongs_to :cardset
  validates_presence_of :title
  # validates_length_of :title, :within => 1..140

  before_create :decide_order

  def decide_order
    self.order = cardset.details_pages.length
    self.title.strip!
  end

  def set_order(new_order)
    other_page = self.cardset.details_pages.find_by_order(new_order)
    my_old_order = self.order
    Rails.logger.info "Trying to set my (#{self.title}) order to #{new_order} and #{other_page && other_page.title}'s order to #{my_old_order}"
    self.order = new_order
    other_page.order = my_old_order
    self.save!
    other_page.save!
  end

  def recency  # For a details page, its order in recency is when it was updated
    updated_at
  end
end
