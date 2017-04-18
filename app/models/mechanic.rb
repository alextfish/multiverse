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
  
  def Mechanic.one_param
    "([^\\]]*)"
  end
  def hide_params?   # Do I contain "\1" or "\2" etc anywhere in my name (expansion)?
    (self.name =~ /[\\][\d]/).present?
  end
  def convert_to_words? 
    (self.reminder =~ /[\\][\d]ASWORDS/)
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
      attributes[:regexps] = [sources, targets]
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
    1000000 => "million",
    1000 => "thousand",
    100 => "hundred",
    90 => "ninety",
    80 => "eighty",
    70 => "seventy",
    60 => "sixty",
    50 => "fifty",
    40 => "forty",
    30 => "thirty",
    20 => "twenty",
    19 => "nineteen",
    18 => "eighteen",
    17 => "seventeen", 
    16 => "sixteen",
    15 => "fifteen",
    14 => "fourteen",
    13 => "thirteen",              
    12 => "twelve",
    11 => "eleven",
    10 => "ten",
    9 => "nine",
    8 => "eight",
    7 => "seven",
    6 => "six",
    5 => "five",
    4 => "four",
    3 => "three",
    2 => "two",
    1 => "one"
  }
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
        str << 'minus ' 
        int = int * -1
      end
    end
  end
end
