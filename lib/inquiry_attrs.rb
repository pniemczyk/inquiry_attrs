# frozen_string_literal: true

require 'active_support'
require 'active_support/concern'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inquiry'

require_relative 'inquiry_attrs/version'
require_relative 'inquiry_attrs/nil_inquiry'
require_relative 'inquiry_attrs/symbol_inquiry'
require_relative 'inquiry_attrs/concern'
require_relative 'inquiry_attrs/installer'

# InquiryAttrs adds predicate-style inquiry methods to Rails model attributes.
#
# Instead of comparing strings:
#
#   user.status == 'active'
#
# Write expressive predicates:
#
#   user.status.active?
#
# Nil/blank values safely return +false+ for all predicates — no more
# +NoMethodError+ on nil.
#
# Run the install task to wire the gem into your Rails app:
#
#   rails inquiry_attrs:install
#
# That creates +config/initializers/inquiry_attrs.rb+ which calls
# +ActiveSupport.on_load(:active_record)+ so that every ActiveRecord model
# gets the +.inquirer+ macro with no explicit include.
#
# For StoreModel or plain Ruby classes, include the concern manually:
#
#   class ShippingAddress
#     include StoreModel::Model
#     include InquiryAttrs::Concern
#
#     attribute :kind, :string
#     inquirer  :kind
#   end
#
module InquiryAttrs
end

# Register the Railtie when running inside a Rails application.
# The Railtie exposes the `rails inquiry_attrs:install` rake task.
require 'inquiry_attrs/railtie' if defined?(Rails::Railtie)
