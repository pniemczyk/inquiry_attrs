# inquiry_attrs

Predicate-style inquiry methods for Rails model attributes.

Instead of comparing strings:

```ruby
user.status == 'active'
user.role == 'admin'
```

Write expressive predicates:

```ruby
user.status.active?
user.role.admin?
```

Nil/blank attributes safely return `false` for every predicate — no more
`NoMethodError` on nil.

---

## Installation

```ruby
# Gemfile
gem 'inquiry_attrs'
```

---

## Quick start

### ActiveRecord — zero configuration

Use rake task to install or uninstall the initializer:

```bash
rails inquiry_attrs:install                              # Install an initializer that auto-includes InquiryAttrs::Concern into ActiveRecord
rails inquiry_attrs:uninstall                            # Remove the inquiry_attrs initializer
```

`inquiry_attrs` auto-includes itself into every `ActiveRecord::Base` subclass
via `ActiveSupport.on_load(:active_record)`. Just call `.inquirer` in any model:

```ruby
class User < ApplicationRecord
  inquirer :status, :kind
end

user = User.new(status: "active", kind: "admin")
user.status.active?   # => true
user.status.inactive? # => false
user.kind.admin?      # => true
user.kind.user?       # => false
```

### Nil / blank attributes

```ruby
user = User.new(status: nil)

user.status.nil?     # => true
user.status.active?  # => false   ← no NoMethodError!
user.status == nil   # => true
```

### String comparison and String methods still work

```ruby
user.status            # => "active"
user.status == 'active'           # => true
user.status.include?('act')       # => true
user.status.upcase                # => "ACTIVE"
```

---

## StoreModel

Include `InquiryAttrs::Concern` explicitly for non-AR classes:

```ruby
class ShippingAddress
  include StoreModel::Model
  include InquiryAttrs::Concern

  attribute :kind, :string   # "shipping", "billing", "return"
  inquirer  :kind
end

address = ShippingAddress.new(kind: "billing")
address.kind.billing?   # => true
address.kind.shipping?  # => false
```

---

## Plain Ruby

```ruby
class Subscription
  include InquiryAttrs::Concern

  attr_accessor :plan, :state

  def initialize(plan:, state: nil)
    @plan  = plan
    @state = state
  end

  # Call inquirer AFTER attr_accessor — the original reader must exist first.
  inquirer :plan, :state
end

sub = Subscription.new(plan: 'enterprise')
sub.plan.enterprise?  # => true
sub.state.nil?        # => true
```

---

## How it works

`.inquirer :attr` wraps the original attribute reader and returns one of three
objects based on the raw value:

| Raw value | Return type | Key behaviour |
|---|---|---|
| `nil` or any blank value | `InquiryAttrs::NilInquiry::INSTANCE` | `nil?` → `true`, all predicates → `false` |
| `Symbol` | `InquiryAttrs::SymbolInquiry` | `:active.active?` → `true` |
| Any other string | `ActiveSupport::StringInquirer` | Standard Rails inquiry |

### `InquiryAttrs::NilInquiry`

A frozen singleton returned for blank attributes. Every `?`-method returns
`false`; behaves like `nil` in comparisons and `blank?` checks.

```ruby
ni = InquiryAttrs::NilInquiry::INSTANCE
ni.nil?       # => true
ni.active?    # => false
ni == nil     # => true
ni.blank?     # => true
```

### `InquiryAttrs::SymbolInquiry`

Wraps a Symbol with predicate methods; compares equal to both the symbol and
its string equivalent.

```ruby
si = InquiryAttrs::SymbolInquiry.new(:active)
si.active?         # => true
si == :active      # => true
si == 'active'     # => true
si.is_a?(Symbol)   # => true
si.to_s            # => "active"
```

---

## API

### `InquiryAttrs::Concern`

Auto-included into `ActiveRecord::Base`. Include manually in other classes.

### `.inquirer(*attribute_names)`

```ruby
inquirer :status                         # single attribute
inquirer :status, :role, :plan           # multiple attributes
```

---

## Development

```bash
bundle install
bundle exec ruby -Ilib -Itest test/inquiry_attrs/nil_inquiry_test.rb \
                                test/inquiry_attrs/symbol_inquiry_test.rb \
                                test/inquiry_attrs/concern_test.rb
```

---

## License

MIT
