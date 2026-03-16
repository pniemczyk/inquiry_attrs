# frozen_string_literal: true

# Example: inquiry_attrs with plain Ruby classes
# Requires explicit `include InquiryAttrs::Concern`.
# IMPORTANT: call `inquirer` AFTER `attr_accessor` — the macro captures
# the original reader at call time; if the reader doesn't exist yet it
# has nothing to wrap.

class Subscription
  include InquiryAttrs::Concern

  attr_accessor :plan, :state

  def initialize(plan:, state: nil)
    @plan  = plan
    @state = state
  end

  # Call inquirer AFTER attr_accessor
  inquirer :plan, :state
end

# Usage
sub = Subscription.new(plan: 'enterprise')

sub.plan.enterprise?  # => true
sub.plan.starter?     # => false
sub.state.nil?        # => true   — state was not set
sub.state.active?     # => false  — nil-safe, no error

sub2 = Subscription.new(plan: 'starter', state: 'active')
sub2.plan.starter?    # => true
sub2.state.active?    # => true
sub2.state.expired?   # => false

# Symbol attributes work too
class Workflow
  include InquiryAttrs::Concern

  def initialize(status)
    @status = status
  end

  def status
    @status  # returns a Symbol
  end

  inquirer :status
end

wf = Workflow.new(:pending)
wf.status.pending?    # => true  — SymbolInquiry wraps it
wf.status == :pending # => true
wf.status == 'pending' # => true
wf.status.is_a?(Symbol) # => true

# ❌ Wrong order — will raise NoMethodError or wrap nil
class BrokenSubscription
  include InquiryAttrs::Concern

  inquirer :plan        # ← captures nil because reader doesn't exist yet
  attr_accessor :plan
end
