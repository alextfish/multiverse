class DeckCardsController < ApplicationController
  before_filter do 
    if params[:deck_card_id]
      @deck_card = DeckCard.find(params[:deck_card_id])
    elsif params[:id]
      @deck_card = DeckCard.find(params[:id])
    end
    if params[:card_id]
      @card = Card.find(params[:card_id])
    elsif params[:deck_card][:card_id]
      @card = Card.find(params[:deck_card][:card_id])
    elsif @deck_card
      @card = @deck_card.card
    end
    if params[:decklist_id]
      @decklist = Decklist.find(params[:decklist_id])
    elsif params[:deck_card][:decklist_id]
      @decklist = Decklist.find(params[:deck_card][:decklist_id])
    elsif @deck_card
      @decklist = @deck_card.decklist
    end
    
    if params[:deck_card] && params[:deck_card][:count] 
      params[:deck_card][:count] = params[:deck_card][:count].to_i
    end
  end
  before_filter do
    require_permission_to_edit(@decklist)
  end

  def create
    count = params[:deck_card][:count]
    @decklist.add_card(@card, count)
    respond_to do |format|
      format.html { redirect_to @decklist }
      format.js
    end
  end

  def update
    if params[:deck_card][:count] == 0
      # This is actually a destroy
      @deck_card.destroy
      respond_to do |format|
        format.html { redirect_to @decklist }
        format.js { render action: :destroy }
      end
    else
      ok = @deck_card.update_attributes(params[:deck_card])
      if !ok
        @deck_card.reload
      end
      respond_to do |format|
        format.html { redirect_to @decklist }
        format.js
      end
    end
  end

  def destroy
    @deck_card.destroy

    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end
end
