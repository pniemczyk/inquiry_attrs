# frozen_string_literal: true

# Example: inquiry_attrs with StoreModel
# Requires explicit `include InquiryAttrs::Concern` for non-AR classes.

class ShippingAddress
  include StoreModel::Model
  include InquiryAttrs::Concern   # required for non-AR classes

  attribute :kind,   :string   # "shipping", "billing", "return"
  attribute :status, :string   # "verified", "pending", "invalid"

  # Call inquirer AFTER attributes are defined
  inquirer :kind, :status
end

class Order < ApplicationRecord
  attribute :shipping_address, ShippingAddress.to_type
  attribute :billing_address,  ShippingAddress.to_type
end

# Usage
order = Order.new(
  shipping_address: { kind: 'shipping', status: 'verified' },
  billing_address:  { kind: 'billing',  status: 'pending'  }
)

order.shipping_address.kind.shipping?    # => true
order.shipping_address.kind.billing?     # => false
order.shipping_address.status.verified?  # => true

order.billing_address.kind.billing?      # => true
order.billing_address.status.pending?    # => true
order.billing_address.status.verified?   # => false

# Nil/blank safety
empty_order = Order.new
empty_order.shipping_address.kind.nil?      # => true
empty_order.shipping_address.kind.shipping? # => false — safe, no error
