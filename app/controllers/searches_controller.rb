class SearchesController < ApplicationController

  def form
    @title = "Search"
  end
  def do_search
  end
  
  def do_quicksearch
    query = params[:q]
    if query.blank?
      redirect_to :back and return
    end
    # We're going to search
    @to_show = {}
    # First: search cardsets
    cardsets = Cardset.find(:all, :conditions => [ "lower(name) = ?", query.downcase ], :include => :configuration).select do |cardset|   # find_all_by_name(query, :include => :configuration)
      permission_to? :view, cardset
    end
    if cardsets.length == 1
      redirect_to cardsets[0] and return
    elsif cardsets.length > 1
      @to_show[:cardsets] = cardsets
    end
    # Okay, not a specific cardset. Try card names.
    cards = Card.find(:all, :conditions => [ "lower(name) = ?", query.downcase ], :include => { :cardset => :configuration }).select do |card|
      permission_to? :view, card.cardset
    end
    if cards.length == 1
      redirect_to cards[0] and return
    elsif cards.length > 1
      @to_show[:cards] = cards
    end
    # List the results if any
    render :action => show
  end
  
  def show
      
  end

end
