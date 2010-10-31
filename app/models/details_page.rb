class DetailsPage < ActiveRecord::Base
  belongs_to :cardset

  def recency  # For a details page, its order in recency is when it was updated
    updated_at
  end
end
