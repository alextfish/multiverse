class SearchesController < ApplicationController

  def advanced
    @title = "Search"
    if params[:search_cardset]
      params[:restrict_cardset_check_card] = true
      params[:restrict_cardset_check_comment] = true
      @cardset = Cardset.find(params[:search_cardset])
      @card = @cardset.cards.build
      @comment = @cardset.comments.build
      # The collection_select in advanced.html.erb will read
      # @card.cardset or @comment.cardset
    end
    Rails.logger.info params.inspect
  end
  
  def do_search
    @to_show = {}
    @object_type = params[:search_type]
    if @object_type.nil? || @object_type.empty? 
      redirect_to :advanced_search and return
    end
    inputs = params[@object_type.to_sym]
    if inputs.nil? || inputs.empty? 
      redirect_to :advanced_search and return
    end
    @query_hash = inputs.clone
    hide_type_string = false
    case @object_type
      when "cardset"
        # Fields are all valid SQL fields: just use multi_search
        valid_keys = ["name", "description", "user_id"]
      when "details_page"
        # Fields are all valid SQL fields: just use multi_search
        valid_keys = ["title", "body"]
      when "comment"
        # Fields are all valid SQL fields: just use multi_search
        valid_keys = ["body", "user_id", "cardset_id"]
      when "card"
        # Field "types" needs processing, and the underscores need removing
        valid_keys = ["name", "rulestext", "flavourtext", "user_id", "cardset_id"]
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
        redirect_to :advanced_search and return
    end
    
    if !(inputs.keys - valid_keys).empty?
      raise "Unexpected #{@object_type} search field found. Fields were: #{inputs.keys.join(", ")}"
    end
    conditions = inputs.map do |key, val| 
      val.blank? ? nil : [key, val, false]
    end.compact
    object_symbol = (@object_type + "s").to_sym # because helpers aren't available here
    @to_show[object_symbol] = multi_search(object_symbol, conditions)
    @query_conditions = inputs
    if hide_type_string
      # replace the ugly multi-part type string with "type"
      @query_conditions["type"] = @query_conditions.delete(type_string)
    end
    
    flat_results = @to_show.values.flatten.compact
    number_results = flat_results.length
    Rails.logger.info "Search returned #{number_results} results"
    # Redirect to one if singleton
    if number_results == 1
      target = flat_results[0]
      case target
        when Card, Cardset
          destination = target 
        when DetailsPage
          destination = [target.cardset, target] 
        when Comment
          parent = target.parent
          case parent
            when Card
              destination = card_path(parent, :anchor => target.anchor_name)
            when Cardset
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
      redirect_to :advanced_search and return
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
    # One last check: is it a card ID?
    Rails.logger.warn("Quicksearch for '#{@query}'")
    card_by_id = Card.find_by_id(@query.to_i)
    if card_by_id && cards.empty? && cardsets.empty?
      redirect_to card_by_id and return
    end
    # At this point, there are either 0 or 2+ hits: do a non-exact search
    @to_show[:cardsets] = one_search(@query, :cardsets, :name, false)
    @to_show[:cards]    = (one_search(@query, :cards, :name, false) + one_search(@query, :cards, :rulestext, false)).uniq
    if card_by_id 
      @to_show[:cards] += [card_by_id]
    end
    
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
        searchable_value = make_even_safer(value.downcase)
        !string.empty? && string += " AND "
        if numeric_field(field)
          field_lowered = field
          comparison = " = ?"
          values = inputs << searchable_value
        elsif exact
          field_lowered = "lower(#{field})"
          comparison = " = ?"
          values = inputs << searchable_value
        else
          field_lowered = "lower(#{field})"
          comparison = " LIKE ?"
          values = inputs << "%#{searchable_value}%"
        end
        [string + field_lowered + comparison, values]
      end.flatten
          Rails.logger.info "Searching for #{queries.inspect}: condition is #{condition.inspect}"
    
      case objects
        when :cardsets
          out = Cardset.includes(:configuration).where( condition).select do |cardset|
                  permission_to? :view, cardset
                end
        when :cards
          out = Card.includes( :cardset => :configuration ).where( condition ).select do |card|
                    permission_to? :view, card.cardset
                  end
        when :details_pages
          out = DetailsPage.includes([ :card, { :cardset => :configuration }]).where( condition ).select do |dp|
                    permission_to? :view, dp.cardset
                  end
        when :comments
          out = Comment.includes([ :card, { :cardset => :configuration }]).where( condition ).select do |comment|
                    permission_to? :view, comment.get_cardset
                  end
        else
          raise "Can't quicksearch for objects type #{objects}"
      end    
    end
    
    def make_even_safer(val)
      return val.gsub(".","_")   # SQL single-char wildcard
    end
    
    def numeric_field(field)
      return ["user_id", "cardset_id"].include? field
    end
    
    def db_concat(*args)
      # By aNoble, from http://stackoverflow.com/questions/2986405/database-independant-sql-string-concatenation-in-rails
      # Symbols should be used for field names, everything else will be quoted as a string
      adapter = ((ActiveRecord::Base.configurations[Rails.env] && ActiveRecord::Base.configurations[Rails.env]['adapter']) || 'postgres').to_sym
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
