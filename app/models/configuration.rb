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
      # "image" => "Card image",
      "prettycard" => "Coloured card layout",
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

end
