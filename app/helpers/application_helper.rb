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
