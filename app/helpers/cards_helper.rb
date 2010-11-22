module CardsHelper

  FORMAT_SUBSTITUTIONS = {
    /\bUEOT\b/i => "until end of turn",
    /\bETBs\b/ => "enters the battlefield",
    /\bETB\b/ => "enter the battlefield",
    /\bCIPs\b/ => "comes into play",
    /\bCIP\b/ => "come into play",
    " // " => "\n",
  }
  MARKUP_SUBSTITUTIONS = {
    /[(]/ => "<i>(",
    /[)]/ => ")</i>",
    "\n" => "<br>",
  }
  AFTER_SUBSTITUTIONS = {
    ": until" => ": Until",
    /^until/ => "Until",
  }
  CARDNAME_ALIASES = ['CARDNAME', '~this~', '~']

  def format(card, attribute, markup = true, escape = true)
    initial_text = card[attribute]
    if initial_text
      if escape
        escaped_text = h initial_text
      else
        escaped_text = initial_text # ONLY for use in <pre>!
      end
      intermediate_text = FORMAT_SUBSTITUTIONS.reduce(escaped_text) do |memo, (match, replace)| memo.gsub(match, replace) end
      if markup
        marked_text = MARKUP_SUBSTITUTIONS.reduce(intermediate_text) do |memo, (match, replace)| memo.gsub(match, replace) end
      else
        marked_text = intermediate_text
      end

      out = AFTER_SUBSTITUTIONS.reduce(marked_text) do |memo, (match, replace)| memo.gsub(match, replace) end
      CARDNAME_ALIASES.each do |string|
        out.gsub!(string, card.name)
      end
      return out.html_safe
    else
      ""  # Required so that we can word_wrap the output
    end
  end
end