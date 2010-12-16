module ApplicationHelper
  def logo
    image_tag("multiverse_logo.png", :alt => "Multiverse", :class => "square")
  end

  def cardset_links(cardsets)
    cardsets.collect do |cardset|
      link_to cardset.name, cardset_path(cardset.id)
    end
  end

  def get_last_edit_user_and_string(object)
    uid = object.last_edit_by
    case
      when uid == User.NON_SIGNED_IN_USER
        [nil, "a non-signed-in user"]
      when uid && !(user = User.find(uid)).nil?     # define user if we can
        [user, user.name]
      else # an edit from before edits were logged (uid==nil) or a user that no longer exists
        [nil, "someone"]
    end
  end
  def link_to_last_edit_user(object)
    user, user_name = get_last_edit_user_and_string(object)
    if user.nil?
      user_name
    else
      link_to user_name, user
    end
  end
  def by_last_edit_user_if_available(object)
    user, user_name = get_last_edit_user_and_string(object)
    if user.nil?
      ""
    else
      "by #{link_to user_name, user}".html_safe
    end
  end

  def format_datetime(dt)
    if dt < 1.week.ago
      # Show older dates in absolute time
      out = "on " + dt.to_date.to_formatted_s(:rfc822)
    else
      time_ago_in_words(dt, :seconds => true) + " ago"
    end
  end

  def format_all_markup(text, cardset)
    formatted_text = protect_smilies(
                       format_mana_symbols(
                         format_mechanics(
                           format_links(text),
                           cardset
                         )
                       )
                     )

    markdown_text = Maruku.new(formatted_text).to_html.html_safe
  end

  def format_links(text)
    # Translate [[[-links and (((-links into Maruku links
    cardset_card_regexp = /\(\(\(([^)]*)\)\)\)/
    wizards_card_regexp = /\[\[\[([^\]]*)\]\]\]/
    remove_brackets_regexp = /([(\[])\1\1(.*)([)\]])\3\3/
    cardset_card_block = lambda { cardset_card_link(@cardset, "$1") }
    wizards_card_block = lambda { wizards_card_link("$1") }

    text_out = text.gsub(cardset_card_regexp) { |cardname|
      cardset_card_link(@cardset, cardname.gsub(remove_brackets_regexp, '\2'))
    }.gsub(wizards_card_regexp) { |cardname|
      wizards_card_link(cardname.gsub(remove_brackets_regexp, '\2'))
    }
  end
  
  def mana_symbol_url ( symbol )
    my_symbol = "" << symbol
    my_symbol.gsub!(/[\{\}\(\)\/]/, "")
    if %w{wr wg uw ug bu bw rb ru gr gb w2 u2 b2 r2 g2}.include? my_symbol.downcase 
      my_symbol.reverse!
    end
    my_symbol.gsub!(/S/, "snow")
    my_symbol.gsub!(/T/, "tap")
    my_symbol.gsub!(/Q/, "untap")
    my_symbol.gsub!(/inf.*/i, "Infinity")
    "http://gatherer.wizards.com/Handlers/Image.ashx?size=small&name=#{my_symbol}&type=symbol"
  end

  def format_mana_symbols(text, force = false) 
    my_text = sanitize(text)
    return my_text
  end
  def format_mana_symbols_really(text, force = false) 
    my_text = sanitize(text)
    return my_text
    if force
      Card.mana_symbols_extensive.each do |sym|
        target = "<img src='#{mana_symbol_url(sym)}'>"
        sym_bare = sym.delete("{}")
        my_text.gsub!( sym_bare, target )
      end
    end
    Card.mana_symbols_extensive.each do |sym|
      target = "<img src='#{mana_symbol_url(sym)}'>"
      sym1 = sym.tr("{}", "()")
      sym2 = sym.delete("/")
      sym3 = sym1.delete("/")
      my_text.gsub!( sym, target )
      my_text.gsub!( sym1, target )
      my_text.gsub!( sym2, target )
      my_text.gsub!( sym3, target )
    end
    my_text.html_safe
  end
  
  def format_mechanics(text, cardset)
    text_out = text
    cardset.mechanics.each do |mech| 
      src_no_reminder, src_with_reminder, target_no_reminder, target_with_reminder = mech.regexps
      text_out.gsub! src_with_reminder, target_with_reminder
      text_out.gsub! src_no_reminder, target_no_reminder
    end
    text_out
  end

  def cardset_card_link(cardset, cardname)
    if (card = cardset.cards.find_by_name(cardname))
      "<a href=\"#{url_for(card)}\">#{cardname}</a>"
    else
      "(((#{cardname})))"
    end
  end
  def wizards_card_link(cardname)
    "<a href=\"http://gatherer.wizards.com/Pages/Search/Default.aspx?name=+[%22#{URI.escape(cardname)}%22]\">#{cardname}</a>"
  end

  def protect_smilies(text)
    text_array = text.split("\n")
    text_array.map { |this_line|
      if [?:, ?<].include?(this_line[0])
        this_line = "&#173;" + this_line
      else
        this_line
      end
    }.join("\n")
  end

  def comment_user_link(comment)
    link_to_unless comment.user.nil?, comment.display_user, comment.user
  end
end
