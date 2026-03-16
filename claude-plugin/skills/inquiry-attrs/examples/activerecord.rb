# frozen_string_literal: true

# Example: inquiry_attrs with ActiveRecord models
# Assumes `rails inquiry_attrs:install` has been run.

class User < ApplicationRecord
  # Wrap multiple attributes at once
  inquirer :status, :role, :plan

  scope :active,    -> { where(status: 'active') }
  scope :suspended, -> { where(status: 'suspended') }
end

class Order < ApplicationRecord
  inquirer :state, :payment_status, :fulfillment_status

  scope :pending,  -> { where(state: 'pending') }
  scope :paid,     -> { where(payment_status: 'paid') }
end

# Usage
user = User.new(status: 'active', role: 'admin', plan: 'pro')

# Predicate methods
user.status.active?     # => true
user.status.inactive?   # => false
user.role.admin?        # => true
user.plan.pro?          # => true

# Nil/blank safety
blank_user = User.new(status: nil)
blank_user.status.nil?    # => true
blank_user.status.active? # => false  — no NoMethodError!
blank_user.status == nil  # => true

# String methods still work
user.status           # => "active"
user.status == 'active'           # => true
user.status.include?('act')       # => true
user.status.upcase                # => "ACTIVE"

# Guard clause pattern
def grant_access(user)
  return :needs_plan  if user.plan.nil?
  return :suspended   if user.status.suspended?
  return :not_admin   unless user.role.admin?

  :granted
end

# Replace case/when
order = Order.new(state: 'pending', payment_status: 'paid')
order.state.pending?          # => true
order.payment_status.paid?    # => true
order.fulfillment_status.nil? # => true (not set)
