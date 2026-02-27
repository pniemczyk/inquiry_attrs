# frozen_string_literal: true

require 'active_record'
require 'store_model'
require 'inquiry_attrs'

require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# In-memory SQLite database shared across all AR tests.
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = nil

# Simulate what `rails inquiry_attrs:install` puts in
# config/initializers/inquiry_attrs.rb so that the AR integration tests work
# without a full Rails boot.
ActiveSupport.on_load(:active_record) do
  include InquiryAttrs::Concern
end
