# encoding: utf-8
class CardSerializer < ActiveModel::Serializer
  include ApplicationHelper
  include CardsHelper

  attributes :name, :type, :supertypes, :types, :subtypes,
              :rarity, :power, :toughness, :text, :flavor, :artist, :sourceURL, :layout
  attribute :cost, key: :manaCost
  attribute :colour_strings_present, key: :colors
  attribute :art_url, key: :artURL
  attribute :image_url, key: :imageURL
  attribute :code, key: :cardCode

  def attributes
    attribs = super

    attribs[:names] = [object.primary_card.name, object.secondary_card.name] if object.multipart?
    attribs[:colorIndicator] = true if object.colour_indicator
    attribs
  end

  def type
    "#{object.supertype} #{object.cardtype}#{' — ' + object.subtype if object.subtype.present?}".strip
  end

  def supertypes
    object.supertype.split(/\s+/)
  end
  def types
    object.cardtype.split(/\s+/)
  end
  def subtypes
    object.subtype.split(/\s+/)
  end

  def text
    format_card_text(object, :rulestext, false, false)
  end

  def flavor
    format_card_text(object, :flavourtext, false, false)
  end

  def sourceURL
    card_url(object)
  end
end
