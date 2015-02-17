class CardsetSummarySerializer < ActiveModel::Serializer
  attributes :name, :code, :sourceURL

  attribute :id, key: :multiverseID
  attribute :updated_at, key: :lastChange

  def code
    "MV#{object.id}"
  end

  def sourceURL
    cardset_url(object, format: :json)
  end

  def owner
    object.user.name
  end
end
