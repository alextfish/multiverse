class GlobalState < ActiveRecord::Base
  # The "singletonguard" column is a unique column which must always be set to '0'
  # This ensures that only one GlobalState row is created
  validates_inclusion_of :singletonguard, :in => [0]
  
  def self.instance
    # there will be only one row, and its ID must be '1'
    begin
      find(1)
    rescue ActiveRecord::RecordNotFound
      # slight race condition here, but it will only happen once
      row = GlobalState.new
      row.singletonguard = 0
      row.save!
      row
    end
  end
end
