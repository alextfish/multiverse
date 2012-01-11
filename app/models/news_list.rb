class NewsList < ActiveRecord::Base
  def NewsList.MAX_LENGTH
    50
  end
  def get_log_ids
    if log_ids 
      log_ids.split(",").map &:to_i 
    else
      []
    end
  end
  def get_logs
    get_log_ids.map do |this_id|
      Log.find this_id
    end
  end
  def get_last_log
    get_logs.last
  end
  def add_log(new_log)
    new_ids = get_log_ids
    if new_ids.length >= NewsList.MAX_LENGTH
      new_ids.shift
    end
    new_ids.push new_log.id
    self.log_ids = new_ids.join ","
    save!
    Rails.logger.info "Adding log of kind #{new_log.kind}"
  end
end
