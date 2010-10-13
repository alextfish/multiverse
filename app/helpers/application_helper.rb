module ApplicationHelper
  def logo
    image_tag("multiverse_logo.png", :alt => "Multiverse", :class => "square")
  end

  def cardset_links(cardsets)
    cardsets.collect do |cardset|
      link_to cardset.name, cardset_path(cardset.id)
    end
  end

  def card_colours
    ["white", "blue", "black", "red", "green", "colourless", "multicolour"]
  end

  def card_frames
    ["White", "Blue", "Black", "Red", "Green", "Artifact", "Multicolour", "Colourless", "Land (colourless)", "Land (white)", "Land (blue)", "Land (black)", "Land (red)", "Land (green)", "Land (multicolour)"]
  end

  def card_rarities
    ["common", "uncommon", "rare", "mythic"]
  end

  def comments_status
    out_hash = {:normal => 0, :unaddressed => 1, :highlighted => 2}
  end
end
