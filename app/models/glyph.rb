# == Schema Information
# Schema version: 20110824232900
#
# Table name: glyphs
#
#  id          :integer         not null, primary key
#  string      :string(255)
#  cardset_id  :integer
#  url         :string(255)
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#

class Glyph < ActiveRecord::Base
  belongs_to :cardset 
  validates :url, :presence => true
  
  validates_format_of :string, :with => /^(\[.*\]|\(.*\)|\{.*\}|<.*>)$/,
    :message => "Glyph string must be enclosed in [], (), {} or <>."
end
