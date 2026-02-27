# inquiry_attrs — Usage Patterns

> Common patterns and recipes for LLMs helping users work with this gem.

## 1. ActiveRecord — no setup needed

```ruby
# Just call inquirer in any AR model.
# No include required — auto-added via ActiveSupport.on_load(:active_record).

class User < ApplicationRecord
  inquirer :status, :role, :plan
end

user = User.new(status: 'active', role: 'admin', plan: 'pro')

user.status.active?    # => true
user.status.inactive?  # => false
user.role.admin?       # => true
user.plan.pro?         # => true
user.plan.free?        # => false

# String methods still work
user.status == 'active'          # => true
user.status.include?('act')      # => true
user.status.upcase               # => "ACTIVE"
```

## 2. Nil / blank safety

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

## 3. Replace case/when string comparisons

```ruby
# Before
case user.status
when 'active'    then grant_access(user)
when 'suspended' then deny_access(user)
when nil, ''     then redirect_to login_path
end

# After
grant_access(user)          if user.status.active?
deny_access(user)           if user.status.suspended?
redirect_to login_path      if user.status.nil?
```

## 4. Scopes and conditions

```ruby
class User < ApplicationRecord
  inquirer :status

  scope :active,    -> { where(status: 'active') }
  scope :suspended, -> { where(status: 'suspended') }
end

# In views or controllers
User.all.select { |u| u.status.active? }
```

## 5. StoreModel

```ruby
class ShippingAddress
  include StoreModel::Model
  include InquiryAttrs::Concern   # required for non-AR classes

  attribute :kind, :string
  inquirer  :kind
end

class Order < ApplicationRecord
  attribute :shipping_address, ShippingAddress.to_type
end

order.shipping_address.kind.billing?   # => true/false
order.shipping_address.kind.nil?       # => true when blank
```

## 6. Plain Ruby class

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
```

## 7. Symbol attributes (e.g., Dry::Struct, enums stored as symbols)

```ruby
# If a reader returns a Symbol, you get SymbolInquiry
si = InquiryAttrs::SymbolInquiry.new(:active)
si.active?        # => true
si.inactive?      # => false
si == :active     # => true
si == 'active'    # => true
si.is_a?(Symbol)  # => true
si.to_s           # => "active"
si.to_sym         # => :active
```

## 8. Testing models with inquirer

```ruby
# Minitest
class UserTest < ActiveSupport::TestCase
  test 'status predicate' do
    user = User.new(status: 'active')
    assert user.status.active?
    refute user.status.inactive?
    assert_equal 'active', user.status
  end

  test 'nil status is safe' do
    user = User.new(status: nil)
    assert user.status.nil?
    refute user.status.active?
  end
end
```

## 9. Detecting NilInquiry in code

```ruby
# Use nil? or == nil — do NOT use is_a?(NilClass)
user.status.nil?             # => true   ✅
user.status == nil           # => true   ✅
user.status.is_a?(NilClass)  # => false  ❌ (it's NilInquiry, not NilClass)

# Or compare to the instance directly
user.status.equal?(InquiryAttrs::NilInquiry::INSTANCE)  # => true
```

## 10. Common mistakes

```ruby
# ❌ Calling inquirer before attr_accessor in plain Ruby
class Broken
  include InquiryAttrs::Concern
  inquirer :status           # no original reader to capture yet!
  attr_accessor :status
end

# ✅ Always after
class Fixed
  include InquiryAttrs::Concern
  attr_accessor :status
  inquirer :status
end

# ❌ Forgetting include for non-AR classes
class MyStoreModel
  include StoreModel::Model
  # include InquiryAttrs::Concern  ← missing!
  inquirer :status               # => NoMethodError
end

# ✅ Explicit include for StoreModel / plain Ruby
class MyStoreModel
  include StoreModel::Model
  include InquiryAttrs::Concern  # ← required
  inquirer :status
end
```

## 11. Difference from `String#inquiry` (ActiveSupport)

| Feature | `"active".inquiry` | `inquirer :status` |
|---|---|---|
| Nil/blank safety | Raises `NoMethodError` | Returns `NilInquiry::INSTANCE` |
| Symbol support | Manual conversion | Automatic `SymbolInquiry` |
| Model integration | Manual wrapping | Declarative macro |
| AR auto-include | No | Yes, via `on_load` |
