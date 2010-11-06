module ApplicationHelper
  def logo
    image_tag("multiverse_logo.png", :alt => "Multiverse", :class => "square")
  end

  def delete_image
    image_tag("delete.png", :alt => "Delete this comment",
                          :title => "Delete this comment")
  end

  def cardset_links(cardsets)
    cardsets.collect do |cardset|
      link_to cardset.name, cardset_path(cardset.id)
    end
  end

  def card_colour_values
    ["white", "blue", "black", "red", "green", "colourless", "multicolour"]
  end

  def card_colours
    ["White", "Blue", "Black", "Red", "Green"]
  end

  def card_frames
    card_colours + ["Artifact", "Multicolour", "Colourless"] +
    colour_pairs.map { |pair| "Hybrid #{pair.join("-").downcase}" } +
    ["Land (colourless)"] + card_colours.map { |col| "Land (#{col.downcase})" } +
    colour_pairs.map { |pair| "Land (#{pair.join('-').downcase})" } +
    ["Land (multicolour)"]
  end
  def colour_pairs
    card_colours.combination(2).to_a
  end

  def card_rarities
    ["common", "uncommon", "rare", "mythic"]
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
end
