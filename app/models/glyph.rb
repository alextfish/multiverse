class Glyph < ActiveRecord::Base
  belongs_to :cardset 
  validates :url, :presence => true
  
  validates_format_of :string, :with => /^(\[.*\]|\(.*\)|\{.*\}|<.*>)$/,
    :message => "Glyph string must be enclosed in [], (), {} or <>."
end
