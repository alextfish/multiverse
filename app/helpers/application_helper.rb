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

  def format_datetime(dt, where = :server)
    formatted_date = dt.utc.to_formatted_s(:db)
    case where
      when :client
        content_tag(:span, :title => formatted_date, :class => "date relative") do
          formatted_date
        end
	  when :server
        content_tag(:span, :title => formatted_date) do
          if dt < 1.week.ago
            # Show older dates in absolute time
            "on " + dt.to_date.to_formatted_s(:rfc822)
          else
            time_ago_in_words(dt, :seconds => true) + " ago"
          end
	    end
	end
  end

  # format_datetime_absolute: Writes the input datetime to the page. It's given a
  # class that will make it formatted as an absolute datetime in the user's locale.
  def format_datetime_absolute(dt)
    formatted_date = dt.utc.to_formatted_s(:db)
    content_tag(:span, :class => "date", :title => formatted_date) do
      formatted_date
    end
  end
  def datestamps_close(d1, d2)
    (d1-d2).abs < 1.minute
  end

  def jf(text)
    # Format and escape for JSON purposes. NOT safe for HTML!
    if text.nil?
      '""'.html_safe
    else
      text.to_s.inspect.html_safe
    end
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

    markdown_text = RDiscount.new(formatted_text, :autolink)
    embed_card_renders(markdown_text.to_html).html_safe
  end

  def self.mana_symbol_url ( symbol )
    my_symbol = "" << symbol
    my_symbol.gsub!(/[\{\}\(\)\/]/, "")
    # Reverse the wrong-order pairs
    if %w{wr wg uw ug bu bw rb ru gr gb w2 u2 b2 r2 g2 w3 u3 b3 r3 g3 wp up bp rp gp}.include? my_symbol.downcase
      my_symbol.reverse!
    end
    my_symbol.gsub!(/S/, "snow")
    my_symbol.gsub!(/C/, "chaos")
    my_symbol.gsub!(/T/, "tap")
    my_symbol.gsub!(/Q/, "untap")
    my_symbol.gsub!(/\?/, "question")
    my_symbol.gsub!(/inf.*/i, "Infinity")
    "/assets/mana/mana_#{my_symbol}.png"
    # "http://gatherer.wizards.com/Handlers/Image.ashx?size=small&name=#{my_symbol}&type=symbol"
  end
  MANA_SYMBOL_TARGETS = Hash.new
  Card.mana_symbols_extensive.each { |sym|
    MANA_SYMBOL_TARGETS[sym] = ActionController::Base.helpers.image_tag(self.mana_symbol_url(sym), :alt=>sym, :title=>sym)
  }


  def format_mana_symbols(text, force = false)
    if text.nil?
      return text
    end
    my_text = sanitize(text)
    if force
      my_text.upcase!
    end
    Card.mana_symbols_extensive.each do |sym|
      target = MANA_SYMBOL_TARGETS[sym]
      fishify(target)
      target.downcase!
      sym0 = Regexp.escape(sym)
      sym1 = sym0.tr("{}", "()")
      sym2 = sym0.delete("/")
      sym3 = sym1.delete("/")
      any_symbol = ("(#{sym0}|#{sym1}|#{sym2}|#{sym3})")
      any_symbol_re = Regexp.new(any_symbol, Regexp::IGNORECASE)
      my_text.gsub!( any_symbol_re, target )
      #my_text.gsub!( sym1, target )
      #my_text.gsub!( sym2, target )
      #my_text.gsub!( sym3, target )
    end
    if force
      Card.mana_symbols_extensive.each do |sym|
        target = MANA_SYMBOL_TARGETS[sym]
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
    # Translate [[[-links and (((-links into Maruku links

    cardset_mockup_regexp   = /\(\(([^)]*)\)\)/
    wizards_image_regexp   = /\[\[([^\]]*)\]\]/
    cardset_link_regexp    = /\(\(\(([^)]*)\)\)\)/
    wizards_link_regexp    = /\[\[\[([^\]]*)\]\]\]/
    card_id_link_regexp    = /\(\(\(C([0-9]+)\)\)\)/
    card_id_mockup_regexp  = /\(\(C([0-9]+)\)\)/
    any_brackets_regexp    = /([(\[][(\[][(\[]?)(.*?[^)\]])([)\]][)\]][)\]]?)/
    remove_brackets_regexp = /([(\[])\1\1?([^(\[].*?[^)\]])([)\]])\3\3?/    # wants to be universal enough to include all the above
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
          if card.split? && card.primary? && !card.link.name.blank?
            # Allow links to "Fire // Ice" as well as "Ice"
            cardset_cardnames_and_codes << card.printable_name
            cardset_cards_from_name_or_code[card.printable_name] = card
          end
        end
        if card.code
          cardset_cardnames_and_codes << card.code
          cardset_cards_from_name_or_code[card.code] = card
        end
      end
    end

    text_out = text_in
    match_count = 0
    text_out.gsub!(remove_brackets_regexp) do |matched_link|
      bracket_contents = matched_link.gsub(remove_brackets_regexp, '\2')
      cardset_present = !!cardset
      image_frame = cardset && cardset.configuration && cardset.configuration.frame == "image"
      case
        when matched_link =~ card_id_link_regexp
          card_id_link(bracket_contents[1..999]) # skip the initial C
        when matched_link =~ card_id_mockup_regexp
          card_id_mockup(bracket_contents[1..999]) # skip the initial C
        when matched_link =~ wizards_link_regexp
          wizards_card_link(bracket_contents, bracket_contents)
        when matched_link =~ wizards_image_regexp
          wizards_card_image(bracket_contents)
        when cardset && any_internal_links && matched_link =~ cardset_link_regexp
          cardset_card_link(cardset, bracket_contents, bracket_contents, cardset_cardnames_and_codes, cardset_cards_from_name_or_code)
        when cardset && any_internal_links && matched_link =~ cardset_mockup_regexp
          if image_frame
            cardset_card_image(cardset, bracket_contents, cardset_cardnames_and_codes, cardset_cards_from_name_or_code)
          else
            cardset_card_mockup(cardset, bracket_contents, cardset_cardnames_and_codes, cardset_cards_from_name_or_code)
          end
        else matched_link
      end
    end
    text_out
  end

  def split_to_json_array(string)
    if string.nil?
      "[]"
    else
      ('["' + string.split(" ").join('", "') + '"]').html_safe
    end
  end

  def link_to_card(card, content = nil, anchor = nil)
    # HTML <a> link to a Multiverse card
    # Content of the link will be card's printable-name unless overridden
    if content.blank?
      content = card.printable_name
    end
    if anchor.blank?
      anchor = "";
    else
      anchor = "#" + anchor;
    end
    # Determine the shape of the desired JS AJAX tooltip
    "<a class=\"cardmockup #{card.tooltip_shape}\" name=\"#{card.id}\" href=\"#{url_for(card)}#{anchor}\">#{sanitize(content)}</a>".html_safe
  end
  def card_id_mockup(this_id)
    if Card.find_by_id(this_id)
      "@@MULTIVERSE@RENDER@#{this_id}@CARD@@"
    else
      "((C#{this_id}))"
    end
  end
  def card_id_link(this_id)
    if (card = Card.find_by_id(this_id))
      link_to_card(card)
    else
      "((C#{this_id}))"
    end
  end
  def cardset_card_link(cardset, cardname, link_content, cardset_cardnames_and_codes, cardset_cards_from_name_or_code)
    if cardset_cardnames_and_codes.include?(cardname)
      card = cardset_cards_from_name_or_code[cardname]
      if link_content == card.code
        # ((MA01)) turns into ((Mindslaver))
        link_content = card.printable_name
      end
      link_to_card(card, link_content)
    elsif link_content =~ Card.bar_code_regexp
      # Link to a bar code. If the cardset has this code, link to that card by name
      # If the cardset doesn't have this code, offer to create it
      actual_code = link_content.slice(Card.code_regexp)
      if cardset_cardnames_and_codes.include?(actual_code)
        card = cardset_cards_from_name_or_code[actual_code]
        link_to_card(card, "#{actual_code} #{card.name}")
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
    "<a class=\"wizardscard\" href=\"http://gatherer.wizards.com/Pages/Search/Default.aspx?name=+[%22#{URI.escape(cardname)}%22]\" name=\"#{wizards_card_image_path(cardname)}\">#{link_content}</a>"
  end
  def wizards_card_image(cardname)
    wizards_card_link(cardname, image_tag(wizards_card_image_path(cardname), :alt => "[[#{cardname}]]", :class => "CardImage"))
  end
  def wizards_card_image_path(cardname)
    # image_name = ActiveSupport::Inflector::parameterize(cardname.gsub("'", ''), '_').gsub('-','_')
    # "http://www.wizards.com/global/images/magic/general/#{image_name}.jpg"
    image_name = cardname.gsub(" ", '+').downcase
    "http://gatherer.wizards.com/Handlers/Image.ashx?type=card&name=#{image_name}"
  end
  def cardset_card_image(cardset, cardname, cardset_cardnames_and_codes, cardset_cards_from_name_or_code)
    if cardset_cardnames_and_codes.include?(cardname)
      card = cardset_cards_from_name_or_code[cardname]
      if card.image_url.blank?
        cardset_card_mockup(cardset, cardname, cardset_cardnames_and_codes, cardset_cards_from_name_or_code)
      else
        link_content = image_tag(card.image_url, :alt => "((#{cardname}))", :class => "CardImage")
        link_to_card(card, link_content)
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
      if @card.split? || @card.dfc?
        @card = @card.primary_card
      elsif @card.flip? && @card.secondary?
        @extra_styles = "rotated"
        @card = @card.primary_card
      end
      Rails.logger.info "Embedding render of #{@card.individual_name}"
      out = "<div class='CardRenderInline'>#{render :partial => 'shared/prettycard', :locals => { :link => true }}</div>"
      @extra_styles = ""
      out
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
        line.sub!("<tr>", "<tr class=\"code_hideable code_frame_#{frame_letter} code_rarity_#{rarity_letter}\">")
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
       candidate = array_in.sample # i.e. random element
       if !chosen.include?(candidate)
         chosen << candidate
       end
     end
     chosen
  end

  def select_random_visible_cards(num_to_choose, cards_array)
     chosen = []
     while chosen.length < num_to_choose
       candidate = cards_array.sample # i.e. random element
       if permission_to?(:view, candidate.cardset) && !chosen.include?(candidate)
         chosen << candidate
       end
     end
     chosen
  end

  #### Link helpers

  def link_to_comment(comment) # logic is duplicated in searches_controller
    parent = comment.parent
    case parent
      when Card
        link_to_card(parent, nil, comment.anchor_name)
      when Cardset
        link_to parent.name, cardset_comments_path(parent, :anchor => comment.anchor_name)
      else
        raise "Don't know how to link_to_comment with parent #{parent}"
    end
  end
  def link_to_comment_user(comment)
    link_to_unless comment.user.nil?, comment.display_user, comment.user
  end
  def reply_to_comment_link(comment)
    case comment.parent
      when Card
        comment.parent
      when Cardset
        new_cardset_comment_path(comment.parent)
    end
  end

  def link_to_log_user(log)
    if (log.comment? && (comment = log.return_object).kind_of?(Comment))
      link_to_comment_user(comment)
    else
      friendly_link_to_user_id log.user_id
    end
  end

  def separate_if_both_nonblank(string1, string2, sep)
    if !string1.blank? && !string2.blank?
      (sanitize(string1) + sep + sanitize(string2)).html_safe
    else
      (sanitize(string1) + sanitize(string2)).html_safe
    end
  end
  def nowrap(string)
    ("<span class='nowrap'>" + sanitize(string) + "</span>").html_safe
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
        when Log.kind(:comment_cardset)
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
        when Log.kind(:mechanic_create), Log.kind(:mechanic_edit)
          cardset = obj.cardset
          return log.past_tense_verb(true) + link_to(cardset.name, cardset_mechanics_path(cardset))
        when Log.kind(:mechanic_delete)
          return log.past_tense_verb(true) + link_to(obj.name, cardset_mechanics_path(obj))
        # For details pages / skeletons, links are nested resources
        when Log.kind(:details_page_create), Log.kind(:details_page_edit), Log.kind(:comment_details_page), Log.kind(:skeleton_generate), Log.kind(:skeleton_edit)
          return log.past_tense_verb(true) + link_to(obj.title, cardset_details_page_path(obj.cardset, obj))
        # For cardset comments, return the cardset name and the cardset comments path
        when Log.kind(:comment_cardset)
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
        when Log.kind(:comment_card)
          # This is complicated by the way I didn't originally store the id for card comments
          if obj.kind_of?(Comment)
            # We have a new-style link with a comment id: link to it
            return log.past_tense_verb(true) + link_to_card(obj.card, nil, obj.anchor_name)
          elsif obj.kind_of?(Card)
            # We have an old-style link with just the card id
            return log.past_tense_verb(true) + link_to_card(obj)
          else
            return log.past_tense_verb(true) + link_to(obj.name, obj)
          end
        # For edited comments, link to either the card, or the cardset comments
        when Log.kind(:comment_edit)
          if obj.card
            return log.past_tense_verb(true) + link_to_card(obj.card, nil, obj.anchor_name)
          else
            return log.past_tense_verb(true) + link_to(obj.cardset.name,
                           cardset_comments_path(obj.cardset, :anchor => obj.anchor_name))
          end
        # For deleted comments, link to the card if there was one, cardset otherwise
        when Log.kind(:comment_delete)
          # And again, sometimes this was the comment id.
          if obj.kind_of?(Card)
            return log.past_tense_verb(true) + link_to_card(obj)
          else
            return log.past_tense_verb(true) + link_to(log.cardset.name, log.cardset)
          end
        # For cards, just give name and path to the object
        when Log.kind(:card_create), Log.kind(:card_edit), Log.kind(:card_create_and_comment)
          if obj
            return log.past_tense_verb(true) + link_to_card(obj)
          else
            return log.past_tense_verb(false)
          end
        # For card moves, give a nicer syntax
        when Log.kind(:card_move_in), Log.kind(:card_move_out)
          if obj
            part1, part2 = log.past_tense_verb(true)
            return part1 + link_to_card(obj) + part2
          else
            return log.past_tense_verb(false)
          end
        # For cardsets, just give name and path to the object
        when Log.kind(:cardset_create), Log.kind(:cardset_options), Log.kind(:cardset_import), Log.kind(:card_delete), Log.kind(:details_page_delete)
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
