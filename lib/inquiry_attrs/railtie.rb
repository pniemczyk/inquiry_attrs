# frozen_string_literal: true

module InquiryAttrs
  class Railtie < Rails::Railtie
    railtie_name :inquiry_attrs

    # Expose `rails inquiry_attrs:install` to the host application.
    rake_tasks do
      load File.expand_path('../tasks/inquiry_attrs.rake', __dir__)
    end
  end
end
