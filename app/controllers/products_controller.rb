class ProductsController < ApplicationController
  def card_specials
    @alt_cards = {}

    @product_week = Product.where(:sku => "weekly.special").first
    @alt_cards[:week], @cards_week = load_cards(@product_week.contents.first)

    @product_day = Product.where(:sku => "card.of.the.day").first
    @alt_cards[:day], @cards_day = load_cards(@product_day.contents.first)

    load_tooltip_data
  end

  private

  def load_cards(item)
    card_id = item.sku.split(".").last

    card = Card.where("$or" => [{:card_id => card_id}, {:alt_card_ids => card_id}]).first

    levels = [card]
    Card.where(:_id.ne => card._id, :set_card_ids.in => [card._id]).each do |card|
      levels << card
    end

    levels.sort_by! {|c| c.level}

    return card.alt_card_ids.include?(card_id), levels
  end
end