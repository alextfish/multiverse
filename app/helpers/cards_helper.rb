module CardsHelper

  FORMAT_SUBSTITUTIONS = {
    /^UEOT\b/i => "Until end of turn",
    /(?<=[:.][)](\s))\s*\bUEOT\b/i => "\1Until end of turn",   # Positive Lookbehind for [:.][)]\s+ , obeying "lookbehind restrictions"
    /(?<=[:.](\s))\s*\bUEOT\b/i => "\1Until end of turn",   # Positive Lookbehind for [:.]\s+ , obeying lookbehind restrictions
    /\bUEOT\b/i => "until end of turn",
    /\bEOT\b/i => "end of turn",
    /\bETBs\b/ => "enters the battlefield",
    /\bETB\b/ => "enter the battlefield",
    /\bOTB\b/ => "onto the battlefield",
    /\bCIPs\b/ => "comes into play",
    /\bCIP\b/ => "come into play",
    /\bCMC\b/ => "converted mana cost",
    " // " => "\n",
  }
  MARKUP_SUBSTITUTIONS = {
    / - / => " &ndash; ",
    / --(\s)/ => " &mdash;\1",
    /\(([^()\n]*)\)/ => '<i>&#40;\1&#41;</i>',
    "\n" => "<br>",
    /\*\*([^*]+)\*\*/ => '<b>\1</b>',
    /\_\_([^_]+)\_\_/ => '<b>\1</b>',
    /(^|[^*])\*([^*]+)\*/ => '\1<i>\2</i>',
    /(^|[^_])\_([^_]+)\_/ => '\1<i>\2</i>',
    /\[(\+[1-9X][0-9X]*)\]/ => '<span class="loyaltyContainer"><span class="loyalty positive">\1</span></span>',
    /\[(\-[1-9X][0-9X]*)\]/ => '<span class="loyaltyContainer"><span class="loyalty negative">\1</span></span>',
    /\[(0|\+0|-0)\]/ => '<span class="loyaltyContainer"><span class="loyalty neutral">\1</span></span>',
  }
  AFTER_SUBSTITUTIONS = {
    ": until" => ": Until",
    /^until/ => "Until",
  }
  CARDNAME_ALIASES_REGEXP = /(CARDNAME|~this~|~)/

  def textbox_chars_displayed(card, attribute)
    text = format_card_text(card, attribute, false, true, false)
    text.length
  end
  def format_card_text(card, attribute, markup = true, escape = true, mana = nil)
    initial_text = card[attribute]
    if mana.nil?   # default mana=markup
      mana = markup
    end
    if initial_text.blank?
      return ""  # Required so that we can word_wrap the output
    end
    
    if escape
      escaped_text = h initial_text
    else
      escaped_text = initial_text # ONLY for use in <pre>!
    end
    intermediate_text = FORMAT_SUBSTITUTIONS.reduce(escaped_text) do |memo, (match, replace)| memo.gsub(match, replace) end
    intermediate_text = format_mechanics(intermediate_text, card.cardset)
    marked_text = intermediate_text
    if markup
      marked_text = MARKUP_SUBSTITUTIONS.reduce(marked_text) do |memo, (match, replace)|
        memo.gsub(match, replace) 
      end
    else
    end
    if mana
      marked_text = format_mana_symbols(marked_text)
    end

    out = AFTER_SUBSTITUTIONS.reduce(marked_text) do |memo, (match, replace)| memo.gsub(match, replace) end
    if card.name.present?
      subsequent_name = (card.supertype =~ /Legendary/) ? card.name.sub(/,.*/, "") : card.name
      out.sub!(CARDNAME_ALIASES_REGEXP, card.name)
      out.gsub!(CARDNAME_ALIASES_REGEXP, subsequent_name)
    end
    return out.html_safe
  end
  
  def displayed_type(card, html=true)
    raw (card.supertype.blank? ? "" : "#{h(card.supertype)} ") +
       (card.cardtype.blank?  ? "" : "#{h(card.cardtype)}") +
       (card.subtype.blank?   ? "" : (html ? " &ndash; " : " - ") + "#{h(card.subtype)}")
  end
  def standard_watermark_filename(watermark)
    watermark_clean = watermark.gsub(/[{}]/, '')
    if Card.known_watermarks.include? watermark_clean
      image_path("/assets/watermarks/#{watermark_clean.downcase.gsub(/ /,'_')}.png")
    else
      ""
    end
  end
end