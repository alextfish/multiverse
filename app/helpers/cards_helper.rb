module CardsHelper

  FORMAT_SUBSTITUTIONS = {
    /\bUEOT\b/i => "until end of turn",
    /\bETBs\b/ => "enters the battlefield",
    /\bETB\b/ => "enter the battlefield",
    /\bCIPs\b/ => "comes into play",
    /\bCIP\b/ => "come into play",
    /\bCMC\b/ => "converted mana cost",
    " // " => "\n",
  }
  MARKUP_SUBSTITUTIONS = {
    /[(]/ => "<i>(",
    /[)]/ => ")</i>",
    / - / => " &ndash; ",
    "\n" => "<br>",
    /\*\*([^*]+)\*\*/ => '<b>\1</b>',
    /\_\_([^_]+)\_\_/ => '<b>\1</b>',
    /(^|[^*])\*([^*]+)\*/ => '\1<i>\2</i>',
    /(^|[^_])\_([^_]+)\_/ => '\1<i>\2</i>',
    /\[(\+[0-9X]+)\]/ => '<span class="loyalty_container"><span class="loyalty positive">\1</span></span>',
    /\[(\-[0-9X]+)\]/ => '<span class="loyalty_container"><span class="loyalty negative">\1</span></span>',
    /\[(0)\]/ => '<span class="loyalty_container"><span class="loyalty neutral">\1</span></span>',
  }
  AFTER_SUBSTITUTIONS = {
    ": until" => ": Until",
    /^until/ => "Until",
  }
  CARDNAME_ALIASES = ['CARDNAME', '~this~', '~']

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
      marked_text = MARKUP_SUBSTITUTIONS.reduce(marked_text) do |memo, (match, replace)| memo.gsub(match, replace) end
    else
    end
    if mana
      marked_text = format_mana_symbols(marked_text)
    end

    out = AFTER_SUBSTITUTIONS.reduce(marked_text) do |memo, (match, replace)| memo.gsub(match, replace) end
    if card.name
      CARDNAME_ALIASES.each do |string|
        out.gsub!(string, card.name)
      end
    end
    return out.html_safe
  end
end