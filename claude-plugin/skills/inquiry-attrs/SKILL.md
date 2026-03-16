---
name: inquiry-attrs
description: This skill should be used when the user asks to "add inquiry_attrs", "install inquiry_attrs", "use inquiry_attrs", "add predicate methods to Rails attributes", "replace string comparison with predicates", "make attribute inquiry work", "add .active? .admin? style methods", "user.status.active?", "nil-safe attribute predicates", or when working with the inquiry_attrs gem in a Rails, StoreModel, or plain Ruby project. Also activate when the user wants to convert `record.attr == 'value'` comparisons to predicate style, or asks about `NilInquiry`, `SymbolInquiry`, or `inquirer` macro.
version: 1.0.0
---

# inquiry_attrs Skill

`inquiry_attrs` adds predicate-style inquiry methods to Rails model attributes, replacing verbose string comparisons with expressive `?`-methods that are nil-safe by design.

## What It Does

```ruby
# Before
user.status == 'active'     # ❌ verbose, breaks on nil

# After
user.status.active?         # ✅ expressive, nil-safe
user.status.nil?            # ✅ true when blank — never raises NoMethodError
```

Return type dispatch (automatic, invisible to the caller):

| Raw attribute value | Object returned | Key behaviour |
|---|---|---|
| `nil` or any blank value | `InquiryAttrs::NilInquiry::INSTANCE` | `nil?` → `true`, all predicates → `false` |
| `Symbol` | `InquiryAttrs::SymbolInquiry` | matches symbol name |
| Any string | `ActiveSupport::StringInquirer` | standard Rails inquiry |

## Installation

See **`references/installation.md`** for full steps. Quick summary:

```ruby
# Gemfile
gem 'inquiry_attrs'
```

```bash
bundle install
rails inquiry_attrs:install   # writes config/initializers/inquiry_attrs.rb
```

The installer writes a single `ActiveSupport.on_load(:active_record)` block that auto-includes `InquiryAttrs::Concern` into every AR model. No manual include needed in AR models.

## Core Usage

### ActiveRecord (zero configuration after install)

```ruby
class User < ApplicationRecord
  inquirer :status, :role, :plan
end

user.status.active?    # => true / false
user.role.admin?       # => true / false
user.plan.nil?         # => true when blank — never raises
user.status == 'active'  # => still works — string methods intact
```

### StoreModel / plain Ruby

Include the concern explicitly for non-AR classes. Call `inquirer` **after** the attribute reader is defined.

```ruby
class ShippingAddress
  include StoreModel::Model
  include InquiryAttrs::Concern   # required for non-AR classes

  attribute :kind, :string
  inquirer  :kind                 # after attribute
end

class Subscription
  include InquiryAttrs::Concern

  attr_accessor :plan
  inquirer :plan                  # after attr_accessor
end
```

### Symbol attributes

```ruby
# If a reader returns a Symbol, SymbolInquiry wraps it automatically.
si = InquiryAttrs::SymbolInquiry.new(:active)
si.active?        # => true
si == :active     # => true
si == 'active'    # => true
si.is_a?(Symbol)  # => true
```

## ⚠️ Reserved Predicate Names — Critical Gotcha

Some predicate names are **real methods** on the returned objects. `method_missing` is never reached for them — they do **not** test string equality.

| Predicate | What it actually does |
|---|---|
| `.nil?` | Always `false` for present values; always `true` for blank |
| `.blank?` | Tests blankness (nil / "" / whitespace) — **not** `value == "blank"` |
| `.present?` | Opposite of `blank?` — **not** `value == "present"` |
| `.empty?` | `true` only for `""` — **not** `value == "empty"` |
| `.frozen?` | Reflects object freeze state |

**Rule:** when a domain value matches one of those names, use direct comparison:

```ruby
order.state == 'blank'   # ✅ correct
order.state.blank?       # ❌ tests blankness, not state == "blank"
```

See **`references/reserved-predicates.md`** for worked examples and all edge cases.

## Testing

```ruby
# Minitest
test 'status predicate' do
  user = User.new(status: 'active')
  assert user.status.active?
  refute user.status.inactive?
  assert_equal 'active', user.status   # string comparison still works
end

test 'nil status is safe' do
  user = User.new(status: nil)
  assert user.status.nil?
  refute user.status.active?
end
```

## Common Mistakes

```ruby
# ❌ inquirer before attr_accessor in plain Ruby
class Broken
  include InquiryAttrs::Concern
  inquirer :status           # no reader to capture yet!
  attr_accessor :status
end

# ✅ always after
class Fixed
  include InquiryAttrs::Concern
  attr_accessor :status
  inquirer :status
end

# ❌ forgetting include for StoreModel / plain Ruby
class MyModel
  include StoreModel::Model
  # missing: include InquiryAttrs::Concern
  inquirer :status           # => NoMethodError
end
```

## Additional Resources

### Reference Files

- **`references/installation.md`** — Step-by-step installation for new and existing projects, initializer content, rake tasks
- **`references/patterns.md`** — Full usage patterns: scopes, case/when replacement, guard clauses, NilInquiry detection
- **`references/reserved-predicates.md`** — Deep dive into reserved predicate names with every edge case

### Examples

- **`examples/activerecord.rb`** — AR model with multiple inquired attrs
- **`examples/storemoderl.rb`** — StoreModel integration
- **`examples/plain_ruby.rb`** — Plain Ruby class
- **`examples/testing.rb`** — Minitest and RSpec test patterns
