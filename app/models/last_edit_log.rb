class LastEditLog < ActiveRecord::Base
  belongs_to :cardset
  belongs_to :user
  
  def what_are_you
    "Log"
  end
end
