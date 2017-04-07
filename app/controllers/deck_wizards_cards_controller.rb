class DeckWizardsCardsController < ApplicationController
  before_filter do 
    if params[:deck_wizards_card_id]
      @deck_wizards_card = DeckWizardsCard.find(params[:deck_wizards_card_id])
    elsif params[:id]
      @deck_wizards_card = DeckWizardsCard.find(params[:id])
    end
    if params[:decklist_id]
      @decklist = Decklist.find(params[:decklist_id])
    elsif params[:deck_wizards_card] && params[:deck_wizards_card][:decklist_id]
      @decklist = Decklist.find(params[:deck_wizards_card][:decklist_id])
    elsif @deck_wizards_card
      @decklist = @deck_wizards_card.decklist
    end
    
    if params[:deck_wizards_card] && params[:deck_wizards_card][:count] 
      params[:deck_wizards_card][:count] = params[:deck_wizards_card][:count].to_i
    end
  end
  before_filter do
    require_permission_to_edit(@decklist)
  end

  def create
    name = params[:deck_wizards_card][:name]
    count = params[:deck_wizards_card][:count] || 1
    section = params[:deck_wizards_card][:section] || "Main"
    @deck_wizards_card = @decklist.add_wizards_card(name, count, section)
    respond_to do |format|
      format.html { redirect_to @decklist }
      format.js
    end
  end

  def update
    if params[:deck_wizards_card][:count] == 0
      # This is actually a destroy
      @deck_wizards_card.destroy
      respond_to do |format|
        format.html { redirect_to @decklist }
        format.js { render action: :destroy }
      end
    else
      ok = @deck_wizards_card.update_attributes(params[:deck_wizards_card])
      if !ok
        @deck_wizards_card.reload
      end
      respond_to do |format|
        format.html { redirect_to @decklist }
        format.js
      end
    end
  end

  def destroy
    @deck_wizards_card.destroy

    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end
end
