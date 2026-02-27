# frozen_string_literal: true

module InquiryAttrs
  # +ActiveSupport::Concern+ that adds the +.inquirer+ macro to any class.
  #
  # For ActiveRecord models this is automatically included via
  # +ActiveSupport.on_load(:active_record)+ — no explicit include needed:
  #
  #   class User < ApplicationRecord
  #     inquirer :status, :role
  #   end
  #
  # For StoreModel, plain Ruby, or any other class, include it manually:
  #
  #   class Address
  #     include StoreModel::Model
  #     include InquiryAttrs::Concern
  #
  #     attribute :kind, :string
  #     inquirer  :kind
  #   end
  #
  module Concern
    extend ActiveSupport::Concern

    class_methods do
      # Wraps the named attribute readers with inquiry behaviour.
      #
      # Returns one of three objects depending on the raw value:
      #
      # * +InquiryAttrs::NilInquiry::INSTANCE+ — when the value is +blank?+
      # * +InquiryAttrs::SymbolInquiry+         — when the value is a +Symbol+
      # * +ActiveSupport::StringInquirer+        — for any other present value
      #   (identical to calling +value.inquiry+ on a string)
      #
      # @param attrs [Array<Symbol>] attribute reader names to wrap
      def inquirer(*attrs)
        attrs.each do |attr|
          # Capture the original reader before we overwrite it.
          # This covers attr_accessor, StoreModel, and AR attribute methods
          # that are already defined by the time inquirer is called.
          original = method_defined?(attr) ? instance_method(attr) : nil

          # Remove the method from this class's own table (not from superclasses)
          # so the define_method below is seen as a fresh definition rather than
          # a redefinition — silencing Ruby's "method redefined" warning.
          remove_method(attr) if instance_methods(false).include?(attr)

          define_method(attr) do
            raw = if original
                    original.bind_call(self)
                  else
                    # Lazy AR attribute methods or Dry::Struct hash access.
                    begin
                      super()
                    rescue NoMethodError
                      begin
                        self[attr]
                      rescue NoMethodError, TypeError
                        nil
                      end
                    end
                  end

            if raw.blank?
              NilInquiry::INSTANCE
            elsif raw.is_a?(Symbol)
              SymbolInquiry.new(raw)
            else
              raw.to_s.inquiry
            end
          end
        end
      end
    end
  end
end
