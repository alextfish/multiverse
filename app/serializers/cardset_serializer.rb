class CardsetSerializer < CardsetSummarySerializer
  attributes :border, :type, :onlineOnly, :booster, :sourceURL
  has_many :cards

  def border
    object.configuration.border_colour
  end

  def type
    "expansion"
  end

  def onlineOnly
    true
  end

  def booster
    object.booster_structure[1]
  end
end
