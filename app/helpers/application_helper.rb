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
      "on " + dt.to_date.to_formatted_s(:rfc822)
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
    "/images/mana/mana_#{my_symbol}.png"
    # "http://gatherer.wizards.com/Handlers/Image.ashx?size=small&name=#{my_symbol}&type=symbol"
  end

  def format_mana_symbols(text, force = false) 
    if text.nil?
      return text
    end
    my_text = sanitize(text)
    if force
      my_text.upcase!
    end
    Card.mana_symbols_extensive.each do |sym|
      target = "<img src='#{mana_symbol_url(sym)}'>"
      fishify(target)
      target.downcase!
      sym1 = sym.tr("{}", "()")
      sym2 = sym.delete("/")
      sym3 = sym1.delete("/")
      my_text.gsub!( sym, target )
      my_text.gsub!( sym1, target )
      my_text.gsub!( sym2, target )
      my_text.gsub!( sym3, target )
    end
    if force
      Card.mana_symbols_extensive.each do |sym|
        target = "<img src='#{mana_symbol_url(sym)}'>".downcase
        fishify(target)
        sym_bare = sym.delete("{}").upcase
        my_text.gsub!( sym_bare, target )
      end
    end
    unfishify(my_text)
    my_text.html_safe
  end
  
  def fishify(text)
    text.gsub!( "0", "zznofish" )
    text.gsub!( "1", "zzonefish" )
    text.gsub!( "2", "zztwofish" )
    text.gsub!( "3", "zzthreefish" )
    text.gsub!( "4", "zzfourfish" )
    text.gsub!( "5", "zzfivefish" )
    text.gsub!( "6", "zzsixfish" )
    text.gsub!( "7", "zzsevenfish" )
    text.gsub!( "8", "zzeightfish" )
    text.gsub!( "9", "zzninefish" )
  end
  
  def unfishify(text)
    text.gsub!( "zznofish"   ,  "0" )
    text.gsub!( "zzonefish"  ,  "1" )
    text.gsub!( "zztwofish"  ,  "2" )
    text.gsub!( "zzthreefish",  "3" )
    text.gsub!( "zzfourfish" ,  "4" )
    text.gsub!( "zzfivefish" ,  "5" )
    text.gsub!( "zzsixfish"  ,  "6" )
    text.gsub!( "zzsevenfish",  "7" )
    text.gsub!( "zzeightfish",  "8" )
    text.gsub!( "zzninefish" ,  "9" )
  end
  
  def format_mechanics(text, cardset)
    text_out = text
    cardset && cardset.mechanics.each do |mech| 
      src_no_reminder, src_with_reminder, target_no_reminder, target_with_reminder = mech.regexps
      #Rails.logger.info [src_no_reminder, src_with_reminder, target_no_reminder, target_with_reminder].join(" --- ")
      # Need the two following lines to be ordered by stricter first
      # e.g. [Bushido 1()] is best parsed as a no-reminder w param 1 than a with-reminder w param 1()
      text_out.gsub! src_no_reminder, target_no_reminder
      text_out.gsub! src_with_reminder, target_with_reminder
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
  
  
  def link_to_log_object(log)
    case log.kind
      # For mechanics, return the cardset name and the mechanics path
      when Log.kind(:mechanic_create), Log.kind(:mechanic_edit):
        obj = Mechanic.find(log.object_id)
        cardset = obj.cardset
        return link_to(cardset.name, cardset_mechanics_path(cardset))
      when Log.kind(:mechanic_delete):
        cardset = Cardset.find(log.object_id)
        return link_to(cardset.name, cardset_mechanics_path(cardset))        
      # For cardset comments, return the cardset name and the cardset comments path
      when Log.kind(:comment_cardset):
        obj = Cardset.find(log.object_id)
        return link_to(obj.name, cardset_comments_path(obj))
      # For edited comments, link to either the card, or the cardset comments
      when Log.kind(:comment_edit):
        comment = Comment.find(log.object_id)
        if comment.card
          return link_to(comment.card.name, comment.card)
        else
          return link_to(comment.cardset.name, cardset_comments_path(comment.cardset))
        end
      # For details pages, links are nested resources
      when Log.kind(:details_page_create), Log.kind(:details_page_edit), Log.kind(:comment_details_page):
        obj = DetailsPage.find(log.object_id)
        return link_to(obj.title, cardset_details_page_path(obj.cardset, obj))
      # For cards and cardsets, just give name and path to the object
      when Log.kind(:cardset_create), Log.kind(:cardset_options), Log.kind(:cardset_import), Log.kind(:details_page_delete):
        obj = Cardset.find(log.object_id)
        display_name = obj ? obj.name : ""
      when Log.kind(:card_create), Log.kind(:card_edit), Log.kind(:comment_card):
        obj = Card.find(log.object_id)
        display_name = obj ? obj.name : ""
      else
        raise "Don't know how to link to logs of kind #{log.kind} such as log #{log.id}"
    end
    return link_to(display_name, obj)
  end
end
