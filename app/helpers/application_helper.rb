module ApplicationHelper
  def logo
    image_tag("multiverse_logo.png", :alt => "Multiverse", :class => "square")
  end

  def cardset_links(cardsets)
    cardsets.collect do |cardset|
      link_to cardset.name, cardset_path(cardset.id)
    end
  end

  def format_datetime(dt)
    dt.to_formatted_s(:long_ordinal)
  end

  def comment_status   # also defined in comment.rb :(
    { :normal => 0,
      :unaddressed => 1,
      :highlighted => 2
    }
  end

  def format_all_markup(text)
    # Translate [[[ into {{{
    pre_formatted_text = text.gsub('[[[', '{{{').gsub(']]]', '}}}')
    markdown_text = Maruku.new(sanitize(pre_formatted_text)).to_html
    formatted_text = format_links(markdown_text).html_safe
  end

  def format_links(text)
    cardset_card_regexp = /\(\(\(([^)]*)\)\)\)/
    wizards_card_regexp = /\{\{\{([^\}]*)\}\}\}/
    remove_brackets_regexp = /([(\{])\1\1(.*)([)\}])\3\3/
    cardset_card_block = lambda { cardset_card_link(@cardset, "$1") }
    wizards_card_block = lambda { wizards_card_link("$1") }

    text_out = text.gsub(cardset_card_regexp) { |cardname|
      cardset_card_link(@cardset, cardname.gsub(remove_brackets_regexp, '\2'))
    }.gsub(wizards_card_regexp) { |cardname|
      wizards_card_link(cardname.gsub(remove_brackets_regexp, '\2'))
    }
  end

  def cardset_card_link(cardset, cardname)
    if (card = cardset.cards.find_by_name(cardname))
      link_to cardname, card
    else
      "(((#{cardname})))"
    end
  end
  def wizards_card_link(cardname)
    link_to cardname, "http://gatherer.wizards.com/Pages/Search/Default.aspx?name=+[%22#{URI.escape(cardname)}%22]"
  end
end
