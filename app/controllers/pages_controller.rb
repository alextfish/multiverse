class PagesController < ApplicationController
  before_filter do
    @mobile_friendly = true
  end
  
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
