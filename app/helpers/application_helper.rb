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
    # Returns a hash: {"white" => "White", "hybrid whiteblue" => "Hybrid white-blue", "land red" => "Land (red)", ...}
    self_named_frames_array = card_colours + ["Artifact", "Multicolour", "Colourless"]
    self_named_frames = self_named_frames_array.map { |f| f.downcase }.zip(self_named_frames_array)

    hybrid_frames = colour_pairs.map { |pair| ["hybrid #{pair.join.downcase}", "Hybrid #{pair.join("-").downcase}"] }

    land_frames =
      [ ["land colourless", "Land (colourless)"] ] +
      card_colours.map { |col| ["land #{col.downcase}", "Land (#{col.downcase})"] } +
      colour_pairs.map { |pair| ["land #{pair.join.downcase}", "Land (#{pair.join('-').downcase})"] } +
      [ ["land multicolour", "Land (multicolour)"] ]

    all_frames_hash = SequencedHash[self_named_frames + hybrid_frames + land_frames]
  end
  def card_frame_dropdowns
    f = card_frames
    f.invert.to_a.unshift(["Auto", "Auto"])
  end

  def colour_pairs
    card_colours.combination(2).to_a
  end

  def card_rarities
    ["common", "uncommon", "rare", "mythic"]
  end

  def comments_status
    out_hash = {:normal => 0, :unaddressed => 1, :highlighted => 2}
  end
end
