# == Schema Information
# Schema version: 20110824232900
#
# Table name: cards
#
#  id           :integer         not null, primary key
#  code         :string(255)
#  name         :string(255)
#  cardset_id   :integer
#  rarity       :string(255)
#  cost         :string(255)
#  supertype    :string(255)
#  cardtype     :string(255)
#  subtype      :string(255)
#  rulestext    :text
#  flavourtext  :text
#  power        :string(255)
#  toughness    :string(255)
#  image        :string(255)
#  active       :boolean
#  created_at   :datetime
#  updated_at   :datetime
#  frame        :string(255)
#  art_url      :string(255)
#  artist       :string(255)
#  image_url    :string(255)
#  last_edit_by :integer
#  multipart    :integer
#  link_id      :integer
#  parent_id    :integer
#  watermark    :string(255)
#

class Card < ActiveRecord::Base
  belongs_to :cardset
  # attr_protected :cardset_id
  
  has_many :comments, :dependent => :destroy
  has_many :old_cards, :dependent => :destroy
  attr_accessor :foil, :blank  # not saved
  belongs_to :link, :class_name => "Card"
  belongs_to :parent, :class_name => "Card"
  accepts_nested_attributes_for :link, :reject_if => proc { |attributes| attributes["rulestext"].blank? && attributes["name"].blank? }
  # has_many :highlighted_comments, :class_name => 'Comment', :conditions => ['status = ?', COMMENT_HIGHLIGHTED]
  # has_many :unaddressed_comments, :class_name => 'Comment', :conditions => ['status = ?', COMMENT_UNADDRESSED]

  before_create :regularise_fields
  before_save :canonicalise_types
  # after_save do  - Can't do this, as we don't have access to session methods in model callbacks :/
  #   set_last_edit(self)
  # end
  
  DEFAULT_RARITY = "none"
  STRING_FIELDS = ["name","cost","supertype","cardtype","subtype","rarity","rulestext","flavourtext","code","frame","art_url","artist","image_url","watermark"]
  LONG_TEXT_FIELDS = ["rulestext", "flavourtext"]
  (STRING_FIELDS-LONG_TEXT_FIELDS).each do |field|
    validates field.to_sym, :length     => { :maximum => 255 }
  end
  # Ensure code is either blank or unique within cardset
  validates_uniqueness_of :code, :scope => [:cardset_id], :allow_blank => true
  # Validate multipart
  def Card.STANDALONE; 0; end
  def Card.SPLIT1;     1; end
  def Card.SPLIT2;     2; end
  def Card.FLIP1;      3; end
  def Card.FLIP2;      4; end
  def Card.DFCFRONT;   5; end
  def Card.DFCBACK;    6; end
  validates_inclusion_of :multipart, :in => [nil, Card.STANDALONE, Card.SPLIT1, Card.SPLIT2, Card.FLIP1, Card.FLIP2, Card.DFCFRONT, Card.DFCBACK]

  def regularise_fields
    # Enforce rarity; default rarity
    if (self.rarity.blank?) || !Card.rarities.include?(self.rarity)
      self.rarity = DEFAULT_RARITY
    end
    # Strip whitespace
    STRING_FIELDS.each do |field|
      if self.attributes[field]
        self.attributes[field].strip!
      end
    end
    # Default multipart
    if self.multipart.nil?
      self.multipart = Card.STANDALONE
    end
  end

  def formatted_rules_text
    format_card_text(rulestext)
  end
  def formatted_flavour_text
    format_card_text(flavourtext)
  end
  
  def primary_card
    secondary? ? parent : self
  end
  def secondary_card
    primary? ? link : self
  end
  
  def individual_name
    case
      when !name.blank?
        name
      when !code.blank?
        code
      else
        "Card#{id}"
    end
  end

  def printable_name
    if !multipart?
      individual_name
    else # printable name for a multipart card
      primary_name = primary_card.individual_name
      secondary_name = secondary_card.individual_name
      if split?
        name_out = primary_name + " // " + secondary_name
      else
        name_out = primary_name 
      end
    end
  end
  
  def listable_name
    if !flip? && !dfc?
      printable_name
    else # In cardlists, flip cards' names are "unflipped (flipped)"
      primary_name = primary_card.individual_name
      secondary_name = secondary_card.individual_name
      "#{primary_name} (#{secondary_name})"
    end
  end

  def recency  # For a card, its order in recency is when it was updated
    updated_at
  end

  def get_history
    possible_logs = Log.find(:all, :conditions => {:object_id => id})
    my_logs = possible_logs.select{|l| l.return_object == self}
    logs_to_not_show = Log.kinds_to_not_show(:card_history)
    my_logs.reject!{|l| logs_to_not_show.include? l.kind}
    out = (comments + my_logs).sort_by &:recency
  end

  def self.colours
    ["White", "Blue", "Black", "Red", "Green"]
  end
  COLOUR_LETTERS = %w{W U B R G}
  def self.colour_letters
    COLOUR_LETTERS
  end

  COLOUR_PAIRS = Card.colours.combination(2).to_a
  def self.colour_pairs
    COLOUR_PAIRS
  end
  
  def self.default_rarity
    DEFAULT_RARITY
  end

  DISPLAY_FRAMES =
    Card.colours + ["Artifact", "Multicolour", "Colourless"] +
    Card.colour_pairs.map { |pair| "Hybrid #{pair.join('-').downcase}" } +
    ["Land (colourless)"] +
    Card.colours.map { |col| "Land (#{col.downcase})" } +
    Card.colour_pairs.map { |pair| "Land (#{pair.join('-').downcase})" } +
    ["Land (multicolour)"]
  def self.display_frames
    DISPLAY_FRAMES
  end
  FRAMES = DISPLAY_FRAMES.map { |f| f.gsub(/[()-]/,'') }
  def self.frames
    FRAMES
  end

  def self.rarities
    %w{none common uncommon rare mythic basic token}
  end
  def self.supertypes
    %w{Legendary Basic World Snow Ongoing}
  end
  def self.category_order
    %w{Colourless White Blue Black Red Green Multicolour Hybrid Split Artifact Land Scheme Plane Vanguard unspecified}
  end
  def self.frame_code_letters
    %w{C W U B R G M Z H S A L E P V}
  end

  mana_symbols = []
  # First the misformed ones
  mana_symbols += COLOUR_LETTERS.map {|s| "{2/#{s}}" }
  mana_symbols += COLOUR_LETTERS.map {|s| "{3/#{s}}" }
  mana_symbols += COLOUR_LETTERS.map {|s| "{#{s}P}" }
  mana_symbols += (0..4).map do |i1|
    i1a = (i1+3).modulo(5)
    i1b = (i1+4).modulo(5)
    ["{#{COLOUR_LETTERS[i1]}/#{COLOUR_LETTERS[i1a]}}", "{#{COLOUR_LETTERS[i1]}/#{COLOUR_LETTERS[i1b]}}"]
  end.flatten
  mana_symbols  += (0..4).map do |i1|
    i1a = (i1+1).modulo(5)
    i1b = (i1+2).modulo(5)
    ["{#{COLOUR_LETTERS[i1]}/#{COLOUR_LETTERS[i1a]}}", "{#{COLOUR_LETTERS[i1]}/#{COLOUR_LETTERS[i1b]}}"]
  end.flatten
  mana_symbols += COLOUR_LETTERS.map {|s| "{#{s}/2}" }
  mana_symbols += COLOUR_LETTERS.map {|s| "{#{s}/3}" }
  mana_symbols += COLOUR_LETTERS.map {|s| "{P#{s}}" }
  mana_symbols += ( COLOUR_LETTERS + %w{1000000 100 10 11 12 13 14 15 16 17 18 19 20 -3 1 2 3 4 5 6 7 8 9 0 X Y T Q S C ?} ) .map {|s| "{#{s}}" }
  MANA_SYMBOLS = mana_symbols

  def self.mana_symbols_extensive
    MANA_SYMBOLS
  end

  # [CURMBT][CWUBRGMZHSAL]\d\d
  rarity_pattern = Card.rarities.reduce("["){ |m,r| m << r.upcase[0] }+"]"
  colour_codes_pattern = "[CWUBRGMZHSAL]"
  code_numbers_pattern = "[0-9][0-9]"
  regexp_string = rarity_pattern + colour_codes_pattern + code_numbers_pattern
  CODE_REGEXP = Regexp.new(regexp_string)
  BAR_CODE_REGEXP = Regexp.new("-" + regexp_string)
  def self.code_regexp
    CODE_REGEXP
  end
  def self.bar_code_regexp
    BAR_CODE_REGEXP
  end

  def Card.interpret_code ( code )
    rarity = Card.rarities.select {|r| r[0] == code.downcase[0]}
    fc_pair = case code[1]
      when ?C then ["Colourless", ""]
      when ?W then ["White", ""]
      when ?U then ["Blue", ""]
      when ?B then ["Black", ""]
      when ?R then ["Red", ""]
      when ?G then ["Green", ""]
      when ?M, ?Z then ["Multicolour", ""]
      when ?H then ["Auto", ""]
      when ?S then ["Auto", ""]
      when ?A then ["Artifact", "Artifact"]
      when ?L then ["Auto", "Land"]
      else ["Auto", ""]
    end
    rarity + fc_pair
  end
  @@colour_regexps = [/w/i, /u/i, /b/i, /r/i, /g/i]
  @@nonhybrid_colour_regexps = [
    /(^|[^\/{(])w|[({]w[})]/i,  # match w either at the start ^, or after anything other than / { (
    /(^|[^\/{(])u|[({]u[})]/i,
    /(^|[^\/{(])b|[({]b[})]/i,
    /(^|[^\/{(])r|[({]r[})]/i,
    /(^|[^\/{(])g|[({]g[})]/i]
  @@colour_affiliation_regexps = [
    ["White", /(\([Ww]\)|\{[Ww]\}|[Pp]lains)/],
    ["Blue",  /(\([Uu]\)|\{[Uu]\}|[Ii]sland)/], 
    ["Black", /(\([Bb]\)|\{[Bb]\}|[Ss]wamp)/], 
    ["Red",   /(\([Rr]\)|\{[Rr]\}|[Mm]ountain)/], 
    ["Green", /(\([Gg]\)|\{[Gg]\}|[Ff]orest)/], 
  ]

  def colours_in_cost
    out = @@colour_regexps.map do |re|
      re.match(cost) ? true : false
    end
  end
  def colour_letters_in_cost
    colours_in_cost.zip(Card.colour_letters).map {|boo, col| (boo ? col.downcase : "")}
  end
  def num_colours
    colours_in_cost.count{|x|x}
  end
  def colour_strings_present
    out = (@@colour_regexps.zip(Card.colours)).map do |re, colour|
      re.match(cost) ? colour : nil
    end.compact
  end
  
  def display_class
    if self.nontraditional_frame?
      # Frames with no other display options
      return self.frame
    end
    if self.frame.nil? || self.frame == "Auto"
      if self.new_record? && self.link.present? && !self.link.new_record?
        cardclass = "" << self.link.calculated_frame
      else
        cardclass = "" << self.calculated_frame
      end
    else
      cardclass = "" << self.frame
    end
    cardclass.gsub!(/[()-]/, "")
    if self.is_planeswalker?
      cardclass << " Planeswalker"
    end
    if self.cardtype =~ /Artifact/ && self.frame != "Artifact"
      cardclass << " Coloured_Artifact"
    end
    # If a flip-half has nothing by this point, remove Colourless class and inherit from parent
    if cardclass == "Colourless" && (self.multipart == Card.FLIP2 || self.multipart == Card.DFCBACK)
      cardclass = self.parent.display_class
    end
    # Add gold pinlines
    if self.num_colours == 2
      cardclass << " " + self.colour_strings_present.join("").downcase
    elsif self.num_colours == 0 && self.parent && self.parent.num_colours == 2
      cardclass << " " + self.parent.colour_strings_present.join("").downcase
    end
    
    if self.is_token?
      cardclass << " token"
    end
    if @extra_styles
      cardclass << " " + @extra_styles
    end
    cardclass
  end
  def converted_mana_cost
    if cost.nil?
      return 0
    end
    # We split three times!
    # First extract parenthesised or braced subexpressions
    cost_tokens = cost.split(/([{(][^})]*[})])/)
    total = 0
    cost_tokens.each do |token|
      if token.match(/[{(]/)
        # This is a bracketed symbol such as (1), {2/G), {15}, {X}, or {W/U}
        total += cmc_of_token(token)
      else
        # This is not bracketed, but potentially a string of tokens such as 11BRG
        # Need to keep numbers grouped
        components = token.split(/([0-9-]+)/)
        components.each do |component|
          # This is either a string of letters like XRR
          # or a string of numbers like 15
          if component.match(/[0-9-]+/)
            total += cmc_of_token(component)
          else
            # This is a string of letters: split into characters
            component.split("").each do |letter|
              total += cmc_of_token(letter)
            end
          end
        end
      end
    end
    total
  end
  def cmc_of_token(token)
    # Return CMC-contribution of one token, such as U, W, X, 11, {3}, (Y), {2/G}
    if token.blank?
      return 0
    end
    internal_number = token.match(/[0-9-]+/)
    if internal_number
      return internal_number[0].to_i
    elsif token.match(/[XYZxyz]/)
      # (X) or (Y) have CMC 0
      return 0
    else
      # Any other bracketed symbol without a number has CMC 1
      return 1
    end
  end
  def border_colour
    if cardset && cardset.configuration && !cardset.configuration.border_colour.blank?
      cardset.configuration.border_colour
    else
      Configuration.DEFAULT_VALUES[:border_colour]
    end
  end
  def colour_indicator_string
    if !colour_indicator
      ""
    else
      frame_to_check = (frame!="Auto" ? frame : calculated_frame)
      case frame_to_check
        when /^(White|Blue|Black|Red|Green)$/
          indic_string = colour_letter_for_colour_name(frame_to_check)
        when /^(Hybrid|Land)/
          colour_regexp = /(white|blue|black|red|green)/i
          matches = frame_to_check.scan(colour_regexp).flatten
          letters = matches.map {|c| colour_letter_for_colour_name(c)}
          indic_string = letters.join("")
        
        when /^(Artifact|Colourless)/
          indic_string = ""
        when /^(Multicolour)/
          # Calculate whether two colours or not
          num_to_check = num_colours
          letters_to_use = colour_letters_in_cost
          if secondary? && num_to_check==0 # Use parent's number
            num_to_check = parent.num_colours
            letters_to_use = parent.colour_letters_in_cost
          end
          if num_to_check==2
            indic_string = letters_to_use.join
          else
            indic_string = "multi"
          end
        else
          indic_string = ""
      end
      indic_string
    end
  end
  def colour_letter_for_colour_name(colour_name)
    case colour_name
      when /White/i then "w"
      when /Blue/i  then "u"
      when /Black/i then "b"
      when /Red/i   then "r"
      when /Green/i then "g"
      when /multicolour/i then "multi"
      else ""
    end
  end

  def category
    if split?
      f = primary_card.frame || primary_card.calculated_frame
      f2 = secondary_card.frame || secondary_card.calculated_frame
      if f != f2
        return "Split"
      end # if they have the same category, list the card in that category
    else
      f = frame || calculated_frame
    end
      
    case f
      when /^Land/
        return "Land"
      when /^(White|Blue|Black|Red|Green|Multicolour|Artifact|Colourless)$/
        return f
      when /^Hybrid/
        return "Hybrid"
      else
        return f
    end
  end
  def category_letter
    case (cat = category)
      when "Blue"
        "U"
      when "Scheme"
        "E" 
      else
        cat[0].chr
    end
  end
  def rarity_letter
    rarity[0].chr.upcase
  end
  def Card.rarity_letters
    Card.rarities.map {|r| r[0].chr.upcase }
  end
  
  def is_token?
    rarity == "token" || frame =~ /Token/i
  end
  
  def is_planeswalker?
    cardtype =~ /Planeswalker/ || frame =~ /Planeswalker/i
  end

  def frame
    if true # Card.frames.include?(attributes["frame"]) || attributes["frame"] == "Auto"
      attributes["frame"]
    else
      calculated_frame
    end
  end

  def calculated_frame
    out = single_card_calculated_frame
    if secondary? && out == "Colourless"
      out = parent.single_card_calculated_frame
    end
    out
  end
    
  def single_card_calculated_frame
    case num_colours
      when 1      # Monocolour is the simplest case
        case cost
          when /w/i then return "White"
          when /u/i then return "Blue"
          when /b/i then return "Black"
          when /r/i then return "Red"
          when /g/i then return "Green"
        end
      when 2      # Two-colour: distinguish between gold and hybrid
                  # We say a card for 1W(W/U)U is gold, but 1W(W/G) is hybrid
        # Count the number of colours present outside hybrid symbols
        colours_present = @@nonhybrid_colour_regexps.reduce(0) do |total, re|
          re.match(cost) ? total+1 : total
        end
        if colours_present >= 2
          return "Multicolour"
        else
          return "Hybrid " + colour_strings_present.join("").downcase
        end
      when 3..5  # Multicolour is easy
        return "Multicolour"
      when 0     # Colourless is either artifact, land, or neither, based on type
        if /land/i.match(cardtype) # Land
          # Could try to detect the text box here, but that's really fiddly to get right
          # Consider Coastal Tower, Arcane Sanctum, Hallowed Fountain, Flooded Strand, and Vivid Creek
          land_colours = []
          @@colour_affiliation_regexps.each do |this_colour, this_regexp|
            if this_regexp.match(rulestext) || this_regexp.match(subtype)
              land_colours << this_colour
            end
          end
          case land_colours.length
            when 0
              return "Land (colourless)" # "Land" # 
            when 1
              return "Land (#{land_colours[0].downcase})" # "Land " + land_colours[0] # 
            when 2
              return "Land (#{land_colours[0].downcase}-#{land_colours[1].downcase})" # "Land " + land_colours.join("").downcase # 
            when 3..5
              return "Land (multicolour)" # "Land multicolour" # 
          end
        elsif /artifact/i.match(cardtype)
          return "Artifact"
        else
          return "Colourless"
        end
    end
  end
  
  def show_whole_card_image?
    is_scheme? || is_plane? # || is_planeswalker? 
  end
  def show_mana_cost?
    !is_token? && !nontraditional_frame? 
  end
  def show_art_box?
    !art_url.blank? && !show_whole_card_image?
  end
  
  def is_scheme?
    frame == "Scheme"
  end
  def is_plane?
    frame == "Plane"
  end
  
  def separator
    if self.split?
      " // "
    elsif self.flip? || self.dfc?
      "<br>&#8209;&#8209;&#8209;&#8209;<br>".html_safe
    else
      ""
    end
  end
  
  def new_linked_card
    Card.new(:cardset => cardset, :frame => frame, :rarity => rarity, :link=>self)
  end
  
  @@printed_card_regexp = ""
  def Card.is_printed_card_name?(some_name)
    if @@printed_card_regexp.blank?
      #file_handle = File.new("singleword.txt")
      #file_contents = file_handle.read(1000000)
      #@@printed_card_regexp = Regexp.new(file_contents)
      @@printed_card_regexp = CardNameRegexps.all_card_names_regexp
    end
    !!(some_name =~ @@printed_card_regexp)
  end

  PLAINS = Card.new(
    :name => "Plains",
    :supertype => "Basic",
    :cardtype => "Land",
    :subtype => "Plains",
    :frame => "Land white",
    :rarity => "basic",
    :watermark => "{White Mana}"
  )
  ISLAND = Card.new(
    :name => "Island",
    :supertype => "Basic",
    :cardtype => "Land",
    :subtype => "Island",
    :frame => "Land blue",
    :rarity => "basic",
    :watermark => "{Blue Mana}"
  )
  SWAMP = Card.new(
    :name => "Swamp",
    :supertype => "Basic",
    :cardtype => "Land",
    :subtype => "Swamp",
    :frame => "Land black",
    :rarity => "basic",
    :watermark => "{Black Mana}"
  )
  MOUNTAIN = Card.new(
    :name => "Mountain",
    :supertype => "Basic",
    :cardtype => "Land",
    :subtype => "Mountain",
    :frame => "Land red",
    :rarity => "basic",
    :watermark => "{Red Mana}"
  )
  FOREST = Card.new(
    :name => "Forest",
    :supertype => "Basic",
    :cardtype => "Land",
    :subtype => "Forest",
    :frame => "Land green",
    :rarity => "basic",
    :watermark => "{Green Mana}"
  )
  def Card.basic_land
    [PLAINS, ISLAND, SWAMP, MOUNTAIN, FOREST]
  end
  def Card.blank(text)
    out = Card.new(:rulestext => text)
    out.blank = true
    out
  end
  
  # The frames which appear in the Frame dropdown
  def nonstandard_frame?
    self.nontraditional_frame? || self.multipart?
  end
  # Specific frames which don't have colour or mana cost
  def nontraditional_frame?
    ["Scheme", "Plane", "Vanguard", "Emblem"].include?(self.frame)
  end
  
  def multipart?
   [Card.SPLIT1, Card.SPLIT2, Card.FLIP1, Card.FLIP2, Card.DFCFRONT, Card.DFCBACK].include?(self.multipart)
  end
  def split?
   [Card.SPLIT1, Card.SPLIT2].include?(self.multipart)
  end
  def flip?
   [Card.FLIP1, Card.FLIP2].include?(self.multipart)
  end
  def dfc?
   [Card.DFCFRONT, Card.DFCBACK].include?(self.multipart)
  end
  def primary?
   [Card.SPLIT1, Card.FLIP1, Card.DFCFRONT].include?(self.multipart)
  end
  def secondary?
   [Card.SPLIT2, Card.FLIP2, Card.DFCBACK].include?(self.multipart)
  end
  def Card.nonsecondary
    select {|c| !c.secondary?}
  end
  def cardframe_class
    nontraditional_frame? ? frame.downcase : split? ? "split" : flip? ? "flip" : dfc? ? "dfc" : ""
  end
  def tooltip_shape
    if cardset.configuration.frame == "image"
      out = "image "
    else
      out = ""
    end
    # Now divide by shape
    if split?  # Split cards are small + landscape
      out += "split"
    elsif dfc? # DFCs are large+landscape
      out += "dfc"
    elsif is_scheme?
      out += "scheme"
    elsif is_plane?
      out += "plane"
    else       # Traditional frame
      out += "portrait"
    end
  end

  def <=>(c2)
    if category != c2.category
      # Sort by category
      return Card.category_order.find_index(category) <=> Card.category_order.find_index(c2.category)
    else
      if ["Multicolour", "Hybrid"].include?(category)
        # Within a category, sort by colour-pair (hybrid / gold), then name
        if num_colours == c2.num_colours
          case num_colours
            when 2
              pair_order = ["WhiteBlue", "BlueBlack", "BlackRed", "RedGreen", "WhiteGreen",
                "WhiteBlack", "BlackGreen", "BlueGreen", "BlueRed", "WhiteRed"
                ]
            when 3
              pair_order = [ # allied triples sorted by Shard order
                "WhiteBlueBlack", "BlueBlackRed", "BlackRedGreen", "WhiteRedGreen", "WhiteBlueGreen",
                # enemy triples sorted by the mutual enemy
                "WhiteBlackRed", "BlueRedGreen", "WhiteBlackGreen", "WhiteBlueRed", "BlueBlackGreen"
                ]
            when 4
              pair_order = [ "WhiteBlueBlackRed", "BlueBlackRedGreen", "WhiteBlackRedGreen", "WhiteBlueRedGreen", "WhiteBlueBlackGreen" ]
            else
              # Both cards are marked as multi or hybrid, but their actual costs have a number of colours 
              # that's either <=1 or >=5. Either way, we don't bother sorting them.
              pair_order = nil
          end
          pair1 = colour_strings_present.join
          pair2 = c2.colour_strings_present.join
          if (!pair_order.nil?) && (pair1 != pair2)
            return pair_order.find_index(pair1) <=> pair_order.find_index(pair2)
          else
            # Just sort by name
            return printable_name <=> c2.printable_name
          end
        else
          # Higher number of colours goes later
          if num_colours != c2.num_colours
            return num_colours <=> c2.num_colours
          else
            # Just sort by name
            return printable_name <=> c2.printable_name
          end
        end
      else
        # Within a category other than multicolour, just sort by name
        return printable_name <=> c2.printable_name
      end
    end
  end

  SUPERTYPES_AND_REGEXPS = Card.supertypes.map do |supertype|
    [supertype, Regexp.new(supertype, true)]   # true -> case-insensitive
  end
  SUBTYPE_DELIMITERS = [" -- ", " - ", "--", "-"]
  def canonicalise_types 
    # Move supertypes to correct places
    SUPERTYPES_AND_REGEXPS.each do |this_supertype, this_regexp|
      if self.cardtype.downcase =~ this_regexp
        if self.supertype.blank?
          self.supertype = this_supertype
        else
          self.supertype += " " + this_supertype
        end
        self.cardtype.slice!(this_regexp)
      end
    end
    # Move subtypes to correct places
    SUBTYPE_DELIMITERS.each do |delimiter|
      if self.cardtype.include?(delimiter) && self.subtype.blank?
        self.cardtype, self.subtype = self.cardtype.split(delimiter)
      end
    end
  end
  
end
