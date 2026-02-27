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

## ⚠️ Reserved predicate names

Some predicate names are **already defined as real methods** on the objects
`inquiry_attrs` returns. Calling them does **not** test whether the attribute
value equals that word — the existing method is called instead and
`method_missing` is never reached.

| Value / predicate | Already defined by | What it actually tests |
|---|---|---|
| `"nil"` / `.nil?` | Ruby `Object#nil?` | Whether the object is `nil` — always `false` for present strings, always `true` for blank values |
| `"blank"` / `.blank?` | ActiveSupport `Object#blank?` | Whether the value is blank (`nil`, `""`, whitespace) — **not** whether it equals `"blank"` |
| `"present"` / `.present?` | ActiveSupport `Object#present?` | Opposite of `blank?` — **not** whether it equals `"present"` |
| `"empty"` / `.empty?` | Ruby `String#empty?` | Whether the string is `""` — **not** whether it equals `"empty"` |
| `"frozen"` / `.frozen?` | Ruby `Object#frozen?` | Whether the object is frozen — **not** whether it equals `"frozen"` |

### Example of the problem

```ruby
class Order < ApplicationRecord
  inquirer :state
end

# ❌ Misleading — .blank? tests blankness, not state == "blank"
order = Order.new(state: 'blank')
order.state.blank?    # => false  ("blank" is a non-empty string, so not blank)

# ❌ Misleading — .present? tests non-blankness, not state == "present"
order = Order.new(state: 'present')
order.state.present?  # => true  (any non-blank string is present)

# ❌ Misleading — .nil? tests object identity, not state == "nil"
order = Order.new(state: 'nil')
order.state.nil?      # => false  (it is a StringInquirer, not nil)
```

**Rule of thumb:** if your domain uses values such as `nil`, `blank`, `present`,
`empty`, or `frozen`, use direct string comparison instead of a predicate:

```ruby
order.state == 'blank'    # ✅ reliable
order.state == 'present'  # ✅ reliable
order.state == 'nil'      # ✅ reliable
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

> **Note:** if an attribute value shares a name with a built-in Ruby/Rails
> predicate (`"nil"`, `"blank"`, `"present"`, `"empty"`, `"frozen"`) the real
> method will be called — not a string-equality check. See
> [⚠️ Reserved predicate names](#️-reserved-predicate-names) for details.

### `InquiryAttrs::NilInquiry`

A frozen singleton returned for blank attributes. Every `?`-method returns
`false`; behaves like `nil` in comparisons, `blank?` checks, and type
introspection.

```ruby
ni = InquiryAttrs::NilInquiry::INSTANCE
ni.nil?                  # => true
ni.active?               # => false
ni == nil                # => true
ni.blank?                # => true
ni.is_a?(NilClass)       # => true
ni.kind_of?(NilClass)    # => true
ni.instance_of?(NilClass) # => true
```

### `InquiryAttrs::SymbolInquiry`

Wraps a Symbol with predicate methods; compares equal to both the symbol and
its string equivalent; reports itself as a `Symbol` in all type-check methods.

```ruby
si = InquiryAttrs::SymbolInquiry.new(:active)
si.active?                # => true
si == :active             # => true
si == 'active'            # => true
si.is_a?(Symbol)          # => true
si.kind_of?(Symbol)       # => true
si.instance_of?(Symbol)   # => true
si.to_s                   # => "active"
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

# Full suite (preferred)
bundle exec rake

# Single file
bundle exec ruby -Ilib -Itest test/inquiry_attrs/concern_test.rb

# Single test by name
bundle exec ruby -Ilib -Itest test/inquiry_attrs/concern_test.rb \
  --name test_matching_predicate_returns_true
```

---

## License

MIT
