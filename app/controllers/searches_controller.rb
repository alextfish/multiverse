class SearchesController < ApplicationController

  def advanced
    @title = "Search"
  end
  def do_search
    @to_show = {}
    object_type = params[:search_type]
    inputs = params[object_type.to_sym]
    @query_hash = inputs.clone
    hide_type_string = false
    case object_type
      when "cardset"
        # Fields are all valid SQL fields: just use multi_search
        valid_keys = ["name", "description"]
      when "details_page"
        # Fields are all valid SQL fields: just use multi_search
        valid_keys = ["title", "body"]
      when "comment"
        # Fields are all valid SQL fields: just use multi_search
        valid_keys = ["body"]
      when "card"
        # Field "types" needs processing, and the underscores need removing
        valid_keys = ["name", "rulestext", "flavourtext"]
        if !inputs["types"].blank?
          # Assemble a string for the full type line in DB-independent fashion
          type_string = db_concat(:"cards.supertype", " ", :"cards.cardtype", " - ", :"cards.subtype")
          # Add this typestring, and permit it
          inputs[type_string] = inputs["types"]
          valid_keys << type_string
          hide_type_string = true
        end
        # Now remove "types" from the inputs (as it'll be present-but-blank if it wasn't specified)
        inputs.delete("types")
        
      else 
        # Unknown object search type
        redirect_to :advancedsearch and return
    end
    
    if inputs.nil? || inputs.empty? 
      rails "Empty search inputs received. Params were: #{params.inspect}"
    end
    
    if !(inputs.keys - valid_keys).empty?
      raise "Unexpected #{object_type} search field found. Fields were: #{inputs.keys.join(", ")}"
    end
    conditions = inputs.map do |key, val| 
      val.blank? ? nil : [key, val, false]
    end.compact
    object_symbol = (object_type + "s").to_sym # because helpers aren't available here
    @to_show[object_symbol] = multi_search(object_symbol, conditions)
    @query = conditions.map { |key, val, f| "#{object_type} #{key}: \"#{val}\"" }.join(", ")
    if hide_type_string
      @query.sub!(type_string, "type")
    end
    
    flat_results = @to_show.values.flatten.compact
    number_results = flat_results.length
    Rails.logger.info "Search returned #{number_results} results"
    # Redirect to one if singleton
    if number_results == 1
      target = flat_results[0]
      case target
        when Card, Cardset:
          destination = target 
        when DetailsPage:
          destination = [target.cardset, target] 
        when Comment:
          parent = target.parent
          case parent
            when Card:
              destination = card_path(parent, :anchor => target.anchor_name)
            when Cardset:
              destination = cardset_comments_path(parent, :anchor => target.anchor_name)
            else
              raise "Don't know how to link_to_comment with parent #{parent}"
          end
      end
      redirect_to destination and return
    end
    # 0 or 2+ results: list them
    render :action => "show"
  end
  
  def do_quicksearch
    @query = params[:q]
    if @query.blank? || @query.length <= 1
      redirect_to :advancedsearch and return
    end
    @quicksearch_query = @query
    # We're going to search
    @to_show = {}
    # First: search cardsets for exact match
    cardsets = one_search(@query, :cardsets, :name, true)
    if cardsets.length == 1
      redirect_to cardsets[0] and return
    elsif cardsets.length > 1
      @to_show[:cardsets] = cardsets
    end
    # Okay, not a specific cardset. Try card names for exact match.
    cards = one_search(@query, :cards, :name, true)
    if cards.length == 1
      redirect_to cards[0] and return
    elsif cards.length > 1
      @to_show[:cards] = cards
    end
    # At this point, there are either 0 or 2+ hits: do a non-exact search
    @to_show[:cardsets] = one_search(@query, :cardsets, :name, false)
    @to_show[:cards]    = (one_search(@query, :cards, :name, false) + one_search(@query, :cards, :rulestext, false)).uniq
    
    number_results = @to_show.values.flatten.length
    Rails.logger.info "Search returned #{number_results} results"
    # Again, redirect to one if singleton
    if number_results == 1
      redirect_to (@to_show[:cardsets][0] || @to_show[:cards][0]) and return
    end
    # 0 or 2+ results: list them
    render :action => "show"
  end
  
  def show
      
  end
  
  # ----------------------
  
  private
  
    def one_search(query, objects, field, exact)
      multi_search(objects, [[field, query, exact]])
    end
    
    def multi_search(objects, queries)
      condition = queries.reduce(["",[]]) do |memo, obj|
        string, inputs = memo
        field, value, exact = obj
        !string.empty? && string += " AND "
        if exact
          [string + "lower(#{field}) = ?", inputs << value.downcase]
        else
          [string + "#{field} LIKE ?", inputs << "%#{value.downcase}%"] 
        end
      end.flatten
          Rails.logger.info "Searching for #{queries.inspect}: condition is #{condition.inspect}"
    
      case objects
        when :cardsets
          out = Cardset.find(:all, 
                             :conditions => condition, 
                             :include => :configuration).select do |cardset|
                  permission_to? :view, cardset
                end
        when :cards
          out = Card.find(:all, 
                          :conditions => condition, 
                          :include => { :cardset => :configuration }).select do |card|
                    permission_to? :view, card.cardset
                  end
        when :details_pages
          out = DetailsPage.find(:all, 
                          :conditions => condition, 
                          :include => { :cardset => :configuration }).select do |dp|
                    permission_to? :view, dp.cardset
                  end
        when :comments
          out = Comment.find(:all, 
                          :conditions => condition, 
                          :include => [ :card, { :cardset => :configuration }]).select do |comment|
                    permission_to? :view, comment.get_cardset
                  end
        else
          raise "Can't quicksearch for objects type #{objects}"
      end    
    end
    
    
    def db_concat(*args)
      # By aNoble, from http://stackoverflow.com/questions/2986405/database-independant-sql-string-concatenation-in-rails
      # Symbols should be used for field names, everything else will be quoted as a string
      adapter = ActiveRecord::Base.configurations[RAILS_ENV]['adapter'].to_sym
      args.map!{ |arg| arg.class==Symbol ? arg.to_s : "'#{arg}'" }

      case adapter
        when :mysql
          "CONCAT(#{args.join(',')})"
        when :sqlserver
          args.join('+')
        else
          args.join('||')
      end

    end

end