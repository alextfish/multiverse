# == Schema Information
# Schema version: 20100926114339
#
# Table name: cardsets
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  user_id     :integer
#  description :text
#  created_at  :datetime
#  updated_at  :datetime


require 'csv'

class Cardset < ActiveRecord::Base
  attr_accessible :name, :description
  belongs_to :user
  has_many :cards
  has_many :admins, :class_name => "User"

  def to_s
    name
  end

  ALIASES = {
    'cardtype' => 'type',
    'manacost' => 'cost',
    'text' => 'rulestext',
    'flavortext' => 'flavourtext',
    'color' => 'colour',
    'notes' => 'comment'
  }
  FIELDS = ['','name','cost','supertype','type','subtype','rarity','rulestext','flavourtext','power','toughness','loyalty','code','colour','comment']
 DEFAULT_RARITY = "common"

  def import_data(params)
    # Initial informative error messages
    if params[:separator].blank?
      return 'Separator character is required'
    end
    if params[:formatting_line].blank?
      return "Formatting line is required"
    end
    if params[:data].blank?
      return "No data supplied"
    end
    if params[:id].blank?
      return "No cardset ID supplied - please re-navigate to this page via the cardset"
    end
    @cardset = Cardset.find(params[:id])

    # Validate the supplied formatting line
    inputfields = params[:formatting_line].split(params[:separator])
    canonfields = inputfields.map{ |f| ALIASES.has_key?(f) ? ALIASES[f] : f }
    validfields = canonfields.select{ |f| FIELDS.include?(f) }
    if validfields != canonfields
      return "The following fields were not recognised: " + (canonfields - validfields).join(", ")
    end

    # We need to detect and reject duplicates of any field, except "" which we allow in multiples
    uniqfields = []
    rejectfields = []
    validfields.each do |f|
      uniqfields.member?(f) && f != "" ? rejectfields <<= f : uniqfields <<= f
    end

    if !rejectfields.empty?
      return "The following fields were duplicated: " + rejectfields.uniq.join(", ")
    end

    fields = uniqfields
    got_rarity = fields.include?("rarity")
    got_comment = fields.include?("comment")

    # Read the CSV
    # Use CSV.parse, which takes care of quoting and newlines for us
    cardsdata = CSV.parse(params[:data], params[:separator]);
    cards = []
    cardsdata.each_with_index do |carddata, index|
      if carddata.length != fields.length
        # Give a nice error message, with 1-based indexing
        return "Line #{index+1} of data had #{carddata.length} fields when expecting #{fields.length}"
      end

      carddatahash = Hash[fields.zip(carddata)]
      # We allow empty strings, to let the data include other values, but we don't want to include them in the post
      if carddatahash.has_key?("")
        carddatahash.delete("")
      end
      if !got_rarity
        carddatahash[:rarity] = DEFAULT_RARITY
      end
      if got_comment
        comment = carddatahash.delete[:comment]
      end
      card = @cardset.cards.build(carddatahash)

      # Don't save the card yet, since there may be a parse error on later lines
      if got_comment && !comment.blank?
        cards << [card, comment]
      else
        cards << [card, nil]
      end
    end

    # We've not returned so far, so the whole data must be good
    cards.each do |cardandcomment|
      card = cardandcomment[0]
      commenttext = cardandcomment[1]
      card.save!
      if !commenttext.nil?
        comment = card.comments.build(:user => current_user, :comment => commenttext)
        comment.save!
      end
    end

    return nil
  end
end
