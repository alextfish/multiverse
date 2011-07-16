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

class Symbol < ActiveRecord::Base
  belongs_to :cardset 
  validates :url, :presence => true
  
  validates_format_of :string, :with => /^(\[.*\]|\(.*\)|\{.*\}|<.*>)$/,
    :message => "Symbol string must be enclosed in [], (), {} or <>."
end
