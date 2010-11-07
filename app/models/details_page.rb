# == Schema Information
# Schema version: 20101103224310
#
# Table name: details_pages
#
#  id         :integer         not null, primary key
#  cardset_id :integer
#  title      :string(255)
#  body       :text
#  created_at :datetime
#  updated_at :datetime
#

class DetailsPage < ActiveRecord::Base
  belongs_to :cardset
  validates_presence_of :title
  # validates_length_of :title, :within => 1..140

  def recency  # For a details page, its order in recency is when it was updated
    updated_at
  end
end
