# inquiry_attrs — Usage Patterns

## Pattern 1: Basic AR Model

```ruby
class User < ApplicationRecord
  inquirer :status, :role, :plan
end

user = User.new(status: 'active', role: 'admin', plan: 'pro')

# Predicate methods
user.status.active?    # => true
user.status.inactive?  # => false
user.role.admin?       # => true
user.plan.free?        # => false

# String methods still work — the returned object behaves as a String
user.status == 'active'          # => true
user.status.include?('act')      # => true
user.status.upcase               # => "ACTIVE"
user.status.to_s                 # => "active"
```

## Pattern 2: Nil / Blank Safety

```ruby
user = User.new(status: nil)

user.status.nil?     # => true
user.status.blank?   # => true
user.status.active?  # => false   ← no NoMethodError!
user.status == nil   # => true
user.status.to_s     # => ""

# Guard pattern
if user.status.nil?
  # handle blank
elsif user.status.active?
  # handle active
end
```

`NilInquiry::INSTANCE` is returned for any blank value: `nil`, `""`,
whitespace-only strings, or any object where `blank?` returns `true`.

## Pattern 3: Replace case/when String Comparisons

```ruby
# Before — fragile, verbose
case user.status
when 'active'    then grant_access(user)
when 'suspended' then deny_access(user)
when nil, ''     then redirect_to login_path
end

# After — expressive, nil-safe
grant_access(user)          if user.status.active?
deny_access(user)           if user.status.suspended?
redirect_to login_path      if user.status.nil?
```

## Pattern 4: Guard Clauses in Service Objects

```ruby
class ActivateUser
  def initialize(user)
    @user = user
  end

  def call
    return if @user.status.active?
    return if @user.plan.nil?

    @user.update!(status: 'active')
  end
end
```

## Pattern 5: Scopes

Scopes still use raw string values for the DB query. Predicates are for
in-memory object state, not SQL generation.

```ruby
class User < ApplicationRecord
  inquirer :status

  scope :active,    -> { where(status: 'active') }
  scope :suspended, -> { where(status: 'suspended') }
end

# In-memory filtering
User.all.select { |u| u.status.active? }

# Combined
User.active.map { |u| u.role.admin? ? 'admin' : 'user' }
```

## Pattern 6: StoreModel Integration

```ruby
class ShippingAddress
  include StoreModel::Model
  include InquiryAttrs::Concern

  attribute :kind, :string   # "shipping", "billing", "return"
  inquirer  :kind
end

class Order < ApplicationRecord
  attribute :shipping_address, ShippingAddress.to_type
end

order.shipping_address.kind.billing?   # => true / false
order.shipping_address.kind.nil?       # => true when blank
```

## Pattern 7: Plain Ruby Class

```ruby
class Subscription
  include InquiryAttrs::Concern

  attr_accessor :plan, :state

  def initialize(plan:, state: nil)
    @plan  = plan
    @state = state
  end

  # IMPORTANT: call inquirer AFTER attr_accessor
  inquirer :plan, :state
end

sub = Subscription.new(plan: 'enterprise')
sub.plan.enterprise?  # => true
sub.state.nil?        # => true
sub.state.active?     # => false — not nil, just safe false
```

## Pattern 8: Symbol Attributes

When a reader returns a `Symbol`, `SymbolInquiry` wraps it automatically.

```ruby
si = InquiryAttrs::SymbolInquiry.new(:active)
si.active?          # => true
si.inactive?        # => false
si == :active       # => true
si == 'active'      # => true
si.is_a?(Symbol)    # => true
si.to_s             # => "active"
si.to_sym           # => :active
```

This is useful when ActiveRecord enums or Dry::Struct store attributes as symbols.

## Pattern 9: Detecting NilInquiry in Code

```ruby
# Use nil? or == nil — do NOT use is_a?(NilClass)
user.status.nil?             # => true   ✅
user.status == nil           # => true   ✅
user.status.is_a?(NilClass)  # => true   ✅ (NilInquiry overrides is_a?)

# Or compare to the singleton directly
user.status.equal?(InquiryAttrs::NilInquiry::INSTANCE)  # => true
```

`NilInquiry` overrides `is_a?`, `kind_of?`, and `instance_of?` for `NilClass`
to return `true`, making it a transparent nil substitute.

## Pattern 10: Multiple Attributes at Once

```ruby
class Order < ApplicationRecord
  inquirer :state, :payment_status, :fulfillment_status, :shipping_method
end

order.state.pending?
order.payment_status.paid?
order.fulfillment_status.shipped?
order.shipping_method.express?
```

## Pattern 11: Difference from `String#inquiry`

| Feature | `"active".inquiry` | `inquirer :status` |
|---|---|---|
| Nil/blank safety | Raises `NoMethodError` | Returns `NilInquiry::INSTANCE` |
| Symbol support | Manual `.to_s` needed | Automatic `SymbolInquiry` |
| Model integration | Manual wrapping | Declarative macro |
| AR auto-include | No | Yes, via `on_load` |

Use `inquirer` in models, not manual `String#inquiry`.
