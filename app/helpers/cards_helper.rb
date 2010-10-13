module CardsHelper

  FORMAT_SUBSTITUTIONS = {
    " // " => "<br>",
    "\n" => "<br>",
    /\bUEOT\b/i => "until end of turn",
    /\bETBs\b/ => "enters the battlefield",
    /\bETB\b/ => "enter the battlefield",
    /\bCIPs\b/ => "comes into play",
    /\bCIP\b/ => "come into play",
    /[(]/ => "<i>(",
    /[)]/ => ")</i>",
  }
  AFTER_SUBSTITUTIONS = {
    ": until" => ": Until",
    /^until/ => "Until",
  }
  CARDNAME_ALIASES = ['CARDNAME', '~this~', '~']

  def format(card, attribute)
    initial_text = card[attribute]
    if initial_text
      escaped_text = h initial_text
      intermediate_text = FORMAT_SUBSTITUTIONS.reduce(escaped_text) do |memo, (match, replace)|
        memo.gsub(match, replace)
      end
      out = AFTER_SUBSTITUTIONS.reduce(intermediate_text) do |memo, (match, replace)|
        memo.gsub(match, replace)
      end
      CARDNAME_ALIASES.each do |string|
        out.gsub!(string, card.name)
      end
      return out.html_safe
    end
  end
end
