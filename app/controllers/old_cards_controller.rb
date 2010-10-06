class OldCardsController < ApplicationController
  # GET /old_cards
  # GET /old_cards.xml
  def index
    @old_cards = OldCard.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @old_cards }
    end
  end

  # GET /old_cards/1
  # GET /old_cards/1.xml
  def show
    @old_card = OldCard.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @old_card }
    end
  end

  # GET /old_cards/new
  # GET /old_cards/new.xml
  def new
    @old_card = OldCard.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @old_card }
    end
  end

  # GET /old_cards/1/edit
  def edit
    @old_card = OldCard.find(params[:id])
  end

  # POST /old_cards
  # POST /old_cards.xml
  def create
    @old_card = OldCard.new(params[:old_card])

    respond_to do |format|
      if @old_card.save
        format.html { redirect_to(@old_card, :notice => 'Old card was successfully created.') }
        format.xml  { render :xml => @old_card, :status => :created, :location => @old_card }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @old_card.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /old_cards/1
  # PUT /old_cards/1.xml
  def update
    @old_card = OldCard.find(params[:id])

    respond_to do |format|
      if @old_card.update_attributes(params[:old_card])
        format.html { redirect_to(@old_card, :notice => 'Old card was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @old_card.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /old_cards/1
  # DELETE /old_cards/1.xml
  def destroy
    @old_card = OldCard.find(params[:id])
    @old_card.destroy

    respond_to do |format|
      format.html { redirect_to(old_cards_url) }
      format.xml  { head :ok }
    end
  end
end
