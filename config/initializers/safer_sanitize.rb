class Application < Rails::Application
  config.after_initialize do
    ActionView::Base.sanitized_allowed_tags.delete 'img'
  end
end