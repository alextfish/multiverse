module ApplicationHelper
  def logo
    image_tag("multiverse_logo.png", :alt => "Multiverse", :class => "square")
  end

  def cardset_links(cardsets)
    cardsets.collect do |cardset|
      link_to cardset.name, cardset_path(cardset.id)
    end
  end

  def friendly_link_to_user_id(uid)
    user, user_name = User.user_and_name_for(uid)
    if user.nil?
      user_name
    else
      link_to user_name, user
    end
  end
  
  def by_last_edit_user_if_available(object)
    uid = object.last_edit_by
    user, user_name = User.user_and_name_for(uid)
    if user.nil?
      ""
    else
      "by #{link_to user_name, user}".html_safe
    end
  end
  
  def show_printable_name(object)
    if object.kind_of? Card
      object.printable_name
    else
      object.name
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
  def format_datetime_absolute(dt)
    content_tag(:span, :class => "date") do
      dt.utc.to_formatted_s(:db)
    end
  end
  def datestamps_close(d1, d2)
    (d1-d2).abs < 1.minute
  end

  def format_all_markup(text, cardset)
    formatted_text = protect_smilies(
                       format_mana_symbols(
                         format_mechanics(
                           format_links(text, cardset),
                           cardset
                         )
                       )
                     )

    markdown_text = RDiscount.new(formatted_text)
    embed_card_renders(markdown_text.to_html).html_safe
  end
  
  def mana_symbol_url ( symbol )
    my_symbol = "" << symbol
    my_symbol.gsub!(/[\{\}\(\)\/]/, "")
    if %w{wr wg uw ug bu bw rb ru gr gb w2 u2 b2 r2 g2 w3 u3 b3 r3 g3}.include? my_symbol.downcase 
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
      # Rails.logger.info [src_no_reminder, src_with_reminder, target_no_reminder, target_with_reminder].join(" --- ")
      # Need the two following lines to be ordered by stricter first
      # e.g. [Bushido 1()] is best parsed as a no-reminder w param 1 than a with-reminder w param 1()
      text_out.gsub! src_no_reminder, target_no_reminder
      text_out.gsub! src_with_reminder, target_with_reminder
    end
    text_out
  end

  def format_links(text_in, cardset)
    # Returns [text-out, out-fcn]
    # Translate [[[-links and (((-links into Maruku links
    
    cardset_image_regexp = /\(\(([^)]*)\)\)/
    wizards_image_regexp = /\[\[([^\]]*)\]\]/
    cardset_card_regexp = /\(\(\(([^)]*)\)\)\)/
    wizards_card_regexp = /\[\[\[([^\]]*)\]\]\]/
    any_brackets_regexp    = /([(\[][(\[][(\[]?)(.*?[^)\]])([)\]][)\]][)\]]?)/
    remove_brackets_regexp = /([(\[])\1\1?(.*[^)\]])([)\]])\3\3?/
    any_internal_links = text_in =~ /\(\(/
    
    # If there are any double-paren links
    if cardset && any_internal_links
      # Build lookup tables so we don't need to do lots of cards.find_by_name
      cardset_cardnames_and_codes = []
      cardset_cards_from_name_or_code = {}
      cardset.cards.each do |card| 
        if card.name 
          cardset_cardnames_and_codes << card.name
          cardset_cards_from_name_or_code[card.name] = card
        end
        if card.code
          cardset_cardnames_and_codes << card.code
          cardset_cards_from_name_or_code[card.code] = card
        end
      end
    end
    
    text_out = text_in
    match_count = 0
    text_out.gsub!(any_brackets_regexp) do |matched_link|
      actual_cardname = matched_link.gsub(remove_brackets_regexp, '\2')
      cardset_present = !!cardset
      image_frame = cardset && cardset.configuration && cardset.configuration.frame == "image"
      case 
        when matched_link =~ wizards_card_regexp:
          wizards_card_link(actual_cardname, actual_cardname)
        when matched_link =~ wizards_image_regexp:
          wizards_card_image(actual_cardname)
        when cardset && any_internal_links && matched_link =~ cardset_card_regexp:
          cardset_card_link(cardset, actual_cardname, actual_cardname, cardset_cardnames_and_codes, cardset_cards_from_name_or_code)
        when cardset && any_internal_links && matched_link =~ cardset_image_regexp:
          if image_frame
            cardset_card_image(cardset, actual_cardname, cardset_cardnames_and_codes, cardset_cards_from_name_or_code)
          else
            cardset_card_mockup(cardset, actual_cardname, cardset_cardnames_and_codes, cardset_cards_from_name_or_code)
          end
        else matched_link
      end
    end
    text_out
  end

  def cardset_card_link(cardset, cardname, link_content, cardset_cardnames_and_codes, cardset_cards_from_name_or_code)
    if cardset_cardnames_and_codes.include?(cardname)
      card = cardset_cards_from_name_or_code[cardname]
      "<a href=\"#{url_for(card)}\">#{link_content}</a>"
    elsif link_content =~ Card.bar_code_regexp
      # Link to a bar code. If the cardset has this code, link to that card by name
      # If the cardset doesn't have this code, offer to create it
      actual_code = link_content.slice(Card.code_regexp)
      if cardset_cardnames_and_codes.include?(actual_code)
        card = cardset_cards_from_name_or_code[actual_code]
        "<a href=\"#{url_for(card)}\">#{actual_code} #{card.name}</a>"
      else
        link_to "(#{actual_code})", new_card_path(:cardset_id => cardset.id, :code => actual_code)
      end
    elsif link_content =~ Card.code_regexp
      # Link to a (valid & safe) code that doesn't yet exist: offer to create it
      link_to "(#{link_content})", new_card_path(:cardset_id => cardset.id, :code => link_content)
    else
      "\(\(\(#{link_content})))" 
    end
  end
  def wizards_card_link(cardname, link_content)
    "<a href=\"http://gatherer.wizards.com/Pages/Search/Default.aspx?name=+[%22#{URI.escape(cardname)}%22]\">#{link_content}</a>"
  end
  def wizards_card_image(cardname)
    image_name = ActiveSupport::Inflector::parameterize(cardname, '_').gsub('-','_')
    wizards_card_link(cardname, image_tag("http://www.wizards.com/global/images/magic/general/#{image_name}.jpg", :alt => "[[#{cardname}]]", :class => "CardImage"))
  end
  def cardset_card_image(cardset, cardname, cardset_cardnames_and_codes, cardset_cards_from_name_or_code)
    if cardset_cardnames_and_codes.include?(cardname)
      card = cardset_cards_from_name_or_code[cardname]
      if card.image_url.blank?
        cardset_card_mockup(cardset, cardname, cardset_cardnames_and_codes, cardset_cards_from_name_or_code)
      else
        cardset_card_link(cardset, cardname, image_tag(card.image_url, :alt => "((#{cardname}))", :class => "CardImage"), cardset_cardnames_and_codes, cardset_cards_from_name_or_code)
      end
    else
      "((#{cardname}))"
    end
  end
  def cardset_card_mockup(cardset, cardname, cardset_cardnames_and_codes, cardset_cards_from_name_or_code)
    if cardset_cardnames_and_codes.include?(cardname)
      card = cardset_cards_from_name_or_code[cardname]
      "@@MULTIVERSE@RENDER@#{card.id}@CARD@@"
    else
      "((#{cardname}))"
    end
  end
  def embed_card_renders(text)
    text.gsub(/@@MULTIVERSE@RENDER@([0-9]*)@CARD@@/) do |matched_string|
      @card = Card.find($1)
      "<div class='CardRenderInline'>#{render :partial => 'shared/prettycard', :locals => { :link => true }}</div>"
    end
  end

  def protect_smilies(text)
    text.lines.map { |this_line|
      if [?:, ?<].include?(this_line[0])
        this_line = "&#173;" + this_line
      else
        this_line
      end
    }.join
  end
  
  def format_skeleton_table(text)
    text.sub!("<th></th>", "")
    text.gsub!(/<tr>\n<td>(\&\#173;)?/, "<tr><td>")
    lines_out = text.lines.map do |line|
      if line =~ Cardset.skeleton_line_regexp_HTML
        data = line.match(Cardset.skeleton_line_regexp_HTML)
        rarity_letter = data[1]
        frame_letter = data[2]
        line.sub!("<tr>", "<tr class=\"code_frame_#{frame_letter} code_rarity_#{rarity_letter}\">")
        line.sub!("<td", "<td class=\"code_link\" ")
      end
      line
    end
    text_out = lines_out.join
    text_out.gsub!(/<td><\/td>\n<\/tr>/, "</tr>")
    text_out.html_safe
  end
  
  def select_random(num_to_choose, array_in)
     chosen = []
     while chosen.length < num_to_choose
       candidate = array_in.choice # i.e. random element
       if !chosen.include?(candidate)
         chosen << candidate
       end
     end
     chosen
  end

  def select_random_visible_cards(num_to_choose, cards_array)
     chosen = []
     while chosen.length < num_to_choose
       candidate = cards_array.choice # i.e. random element
       if permission_to?(:view, candidate.cardset) && !chosen.include?(candidate)
         chosen << candidate
       end
     end
     chosen
  end
  
  def link_to_comment(comment) # logic is duplicated in searches_controller
    parent = comment.parent
    case parent
      when Card:
        link_to parent.printable_name, card_path(parent, :anchor => comment.anchor_name)
      when Cardset:
        link_to parent.name, cardset_comments_path(parent, :anchor => comment.anchor_name)
      else
        raise "Don't know how to link_to_comment with parent #{parent}"
    end
  end
  def link_to_comment_user(comment)
    link_to_unless comment.user.nil?, comment.display_user, comment.user
  end
  
  def link_to_log_object(log)
    if log.nil?
      # Can't get anything from this
      return log.past_tense_verb(false)
    end
    obj = log.return_object
    if obj.nil?
      # Logs for a deleted object
      # Just return the kind of object we were expecting
      case log.kind
        # Comments: complicated by the way I didn't originally store the id of the comment itself
        when Log.kind(:comment_cardset):
          # There may be a cardset id still available
          if log.cardset
            return log.past_tense_verb(true) + link_to(log.cardset.name, log.cardset)
          else
            return log.past_tense_verb(false)
          end
        else
          return log.past_tense_verb(false)
      end
    else
      case log.kind
        # For mechanics, return the cardset name and the mechanics path
        when Log.kind(:mechanic_create), Log.kind(:mechanic_edit):
          cardset = obj.cardset
          return log.past_tense_verb(true) + link_to(cardset.name, cardset_mechanics_path(cardset))
        when Log.kind(:mechanic_delete):
          return log.past_tense_verb(true) + link_to(obj.name, cardset_mechanics_path(obj)) 
        # For details pages / skeletons, links are nested resources
        when Log.kind(:details_page_create), Log.kind(:details_page_edit), Log.kind(:comment_details_page), Log.kind(:skeleton_generate), Log.kind(:skeleton_edit):
          return log.past_tense_verb(true) + link_to(obj.title, cardset_details_page_path(obj.cardset, obj))
        # For cardset comments, return the cardset name and the cardset comments path
        when Log.kind(:comment_cardset):
          # This is complicated by the way I didn't originally store the id for cardset comments
          if obj.kind_of?(Comment)
            # We have a new-style link with a comment id: link to it
            return log.past_tense_verb(true) + link_to(obj.cardset.name, 
                           cardset_comments_path(obj.cardset, :anchor => obj.anchor_name))
          else
            # We have an old-style link with just the cardset id
            return log.past_tense_verb(true) + link_to(obj.name, cardset_comments_path(obj))
          end
        # For card comments, return the card name and the card comment anchor
        when Log.kind(:comment_card):
          # This is complicated by the way I didn't originally store the id for card comments
          if obj.kind_of?(Comment)
            # We have a new-style link with a comment id: link to it
            return log.past_tense_verb(true) + link_to(obj.card.printable_name, card_path(obj.card, :anchor => obj.anchor_name))
          elsif obj.kind_of?(Card)
            # We have an old-style link with just the card id
            return log.past_tense_verb(true) + link_to(obj.printable_name, obj)
          else
            return log.past_tense_verb(true) + link_to(obj.name, obj)
          end
        # For edited comments, link to either the card, or the cardset comments
        when Log.kind(:comment_edit):
          if obj.card
            return log.past_tense_verb(true) + link_to(obj.card.printable_name, card_path(obj.card, :anchor => obj.anchor_name))
          else
            return log.past_tense_verb(true) + link_to(obj.cardset.name, 
                           cardset_comments_path(obj.cardset, :anchor => obj.anchor_name))
          end
        # For deleted comments, link to the card if there was one, cardset otherwise
        when Log.kind(:comment_delete):
          # And again, sometimes this was the comment id.
          if obj.kind_of?(Card)
            return log.past_tense_verb(true) + link_to(obj.printable_name, obj)
          else
            return log.past_tense_verb(true) + link_to(log.cardset.name, log.cardset)
          end
        # For cards, just give name and path to the object
        when Log.kind(:card_create), Log.kind(:card_edit):
          if obj 
            return log.past_tense_verb(true) + link_to(obj.printable_name, obj)
          else
            return log.past_tense_verb(false)
          end
        # For cardsets, just give name and path to the object
        when Log.kind(:cardset_create), Log.kind(:cardset_options), Log.kind(:cardset_import), Log.kind(:card_delete), Log.kind(:details_page_delete):
          if obj 
            return log.past_tense_verb(true) + link_to(obj.name, obj)
          else
            return log.past_tense_verb(false)
          end
        else
          raise "Don't know how to link to logs of kind #{log.kind} such as log #{log.id}"
      end
    end
  end
end
