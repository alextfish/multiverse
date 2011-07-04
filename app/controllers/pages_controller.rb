class PagesController < ApplicationController

  def home
    @title = "Home"
  end

  def contact
    @title = "Contact"
  end
  
  def card_back
    @printable = true
    @embedded = true
  end

end
