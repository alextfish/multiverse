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

  def format_all_markup(text)
    formatted_text = protect_smilies(format_links(text))

    markdown_text = Maruku.new(sanitize(formatted_text)).to_html.html_safe
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
