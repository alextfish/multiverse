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

class Mechanic < ActiveRecord::Base
  belongs_to :cardset, touch: true
  attr_protected :cardset_id
  
  validates :name, :presence => true
  validates :codename, :presence => true
  validates_inclusion_of :parameters, :in => (0..2)
  
  attr_accessor :regexps
  
  before_save :canonicalise_params
  
  ONE_PARAM_REGEXP = "([^\\]]*)".freeze
  def Mechanic.one_param
    ONE_PARAM_REGEXP
  end
  BACKSLASH_DIGIT_REGEXP = /[\\][\d]/.freeze
  def hide_params?   # Do I contain "\1" or "\2" etc anywhere in my name (expansion)?
    (self.name =~ BACKSLASH_DIGIT_REGEXP).present?
  end
  BACKSLASH_DIGIT_AS_WORDS_REGEXP = /[\\][\d]ASWORDS/.freeze
  def convert_to_words? 
    (self.reminder =~ BACKSLASH_DIGIT_AS_WORDS_REGEXP)
  end
  
  def canonicalise_params
    # Convert any supplied PARAM1 in name or reminder to \1 for internal matching
    self.name.gsub!     /PARAM(?<digit>\d)/, "\\\\\\k<digit>" # literal backslash, then the digit we matched
    self.reminder.gsub! /PARAM(?<digit>\d)/, "\\\\\\k<digit>" # literal backslash, then the digit we matched
  end
  def displayed_reminder
    self.reminder.gsub /\\(?<digit>\d)/, "PARAM\\k<digit>"
  end
  
  def apply(text_out)
    sources, targets = self.regexps
    
    sources.zip(targets).each do |source, target|
      text_out.gsub! source, target
    end
    if text_out && convert_to_words?
      text_out.gsub!( /([\d]+)ASWORDS/ ) { |match|
        match.gsub($&, Mechanic.num_to_words($1.to_i))
      }
    end
    return text_out
  end
  
  def regexps
    if attributes[:regexps].nil?
      sep = " "
      codename_Upper = self.codename[0].upcase   + self.codename[1..9999];
      codename_lower = self.codename[0].downcase + self.codename[1..9999];
      sources_start = [codename_Upper, codename_lower].map {|s| "\\[" + s};
      
      name_Upper = self.name[0].upcase   + self.name[1..9999];
      name_lower = self.name[0].downcase + self.name[1..9999];
      targets_start = [name_Upper, name_lower];
      
      case self.parameters 
        when 0
          sources_main = sources_start;
          targets_main = targets_start;
        when 1
          sources_main = sources_start.map {|s| s + sep + Mechanic.one_param };
          targets_main = targets_start.map {|t| (self.hide_params? ? t : t + ' \\1') };
        when 2
          sources_main = sources_start.map {|s| s + sep + Mechanic.one_param + sep + Mechanic.one_param };
          targets_main = targets_start.map {|t| (self.hide_params? ? t : t + ' \\1 - \\2') };
      end
      # Need the two following lines to be ordered by stricter first
      # e.g. [Bushido 1()] is best parsed as a no-reminder w param 1 than a with-reminder w param 1()
      sources_no_reminder   = sources_main.map {|s| Regexp.new(s + "\\(\\)\\]", false) }; # false -> case-sensitive (don't ignore case)
      sources_with_reminder = sources_main.map {|s| Regexp.new(s +       "\\]", false) };
      
      targets_no_reminder = targets_main;
      targets_with_reminder = targets_main.map {|t| t + (self.reminder.blank? ? "" : " (#{self.reminder})") };
      
      sources = sources_no_reminder + sources_with_reminder
      targets = targets_no_reminder + targets_with_reminder
      attributes[:regexps] = [sources.map(&:freeze), targets.map(&:freeze)]
    else
      attributes[:regexps]
    end
  end
  
  def Mechanic.wizards_mechanics
    if @wizards_mechanics
      @wizards_mechanics
    elsif (cs = Cardset.find_by_name("Wizards Mechanics")) && (cs.user_id == 1)
      @wizards_mechanics = cs.mechanics
    else
      @wizards_mechanics = []
    end
  end
  
  # Number-to-word code from http://stackoverflow.com/a/26220538/28234
  NUMBERS_TO_NAME = {
    1000000 => "million".freeze,
    1000 => "thousand"  .freeze,
    100 => "hundred"    .freeze,
    90 => "ninety"      .freeze,
    80 => "eighty"      .freeze,
    70 => "seventy"     .freeze,
    60 => "sixty"       .freeze,
    50 => "fifty"       .freeze,
    40 => "forty"       .freeze,
    30 => "thirty"      .freeze,
    20 => "twenty"      .freeze,
    19 => "nineteen"    .freeze,
    18 => "eighteen"    .freeze,
    17 => "seventeen"   .freeze,
    16 => "sixteen"     .freeze,
    15 => "fifteen"     .freeze,
    14 => "fourteen"    .freeze,
    13 => "thirteen"    .freeze,
    12 => "twelve"      .freeze,
    11 => "eleven"      .freeze,
    10 => "ten"         .freeze,
    9 => "nine"         .freeze,
    8 => "eight"        .freeze,
    7 => "seven"        .freeze,
    6 => "six"          .freeze,
    5 => "five"         .freeze,
    4 => "four"         .freeze,
    3 => "three"        .freeze,
    2 => "two"          .freeze,
    1 => "one"          .freeze
  }.freeze
  def Mechanic.num_to_words(int)
    str = ""
    NUMBERS_TO_NAME.each do |num, name|
      if int == 0
        return str
      elsif int.to_s.length == 1 && int/num > 0
        return str + "#{name}"
      elsif int < 100 && int/num > 0
        return str + "#{name}" if int%num == 0
        return str + "#{name} " + num_to_words(int%num)
      elsif int/num > 0
        return str + num_to_words(int/num) + " #{name} " + ((rem=num_to_words(int%num)).blank? ? "" : "and " + rem)
      elsif int < 0
        str << "minus "
        int = int * -1
      end
    end
  end
end
