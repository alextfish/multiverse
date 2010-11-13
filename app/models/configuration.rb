# == Schema Information
# Schema version: 20101103224310
#
# Table name: configurations
#
#  id                     :integer         not null, primary key
#  cardset_id             :integer
#  frame                  :string(255)
#  use_highlighting       :boolean
#  use_addressing         :boolean
#  default_comment_state  :string(255)
#  cardlist_show_comments :boolean
#  cardlist_show_code     :boolean
#  cardlist_show_active   :boolean
#  card_show_code         :boolean
#  card_show_active       :boolean
#  visibility             :string(255)
#  commentability         :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#

class Configuration < ActiveRecord::Base
  attr_protected :id

  belongs_to :cardset

    people_options = {
      :anyone => "Anyone",
      :signedin => "Signed-in users",
      :admins => "Admins only",
      # :selected => "Selected users:"
    }
  @@legal_values_internal = {
    :frame => {
      "image" => "Supplied image",
      "prettycard" => "Coloured card mockup",
      "plain" => "Plain text",
    },
    :default_comment_state => {
      "unaddressed" => "Unaddressed",
      "normal" => "Normal",
    },
    :visibility => people_options,
    :commentability => people_options,
  }
  validators = Hash[ @@legal_values_internal.map do |prop, values_hash|
    [prop, Regexp.new( values_hash.keys.join('|') )]
  end ]

  validators.keys.each do |thisprop|
    validates thisprop, :presence => true,
                        :format   => { :with => validators[thisprop] }
  end

  def legal_values
    @@legal_values_internal
  end

  def set_default_values!
    self.attributes = {
      :frame                  => 'prettycard',
      :use_highlighting       => true,
      :use_addressing         => true,
      :default_comment_state  => 'unaddressed',
      :cardlist_show_comments => true,
      :cardlist_show_code     => false,
      :cardlist_show_active   => false,
      :card_show_code         => false,
      :card_show_active       => false,
      :visibility             => 'anyone',
      :commentability         => 'anyone',
    }
  end

end
