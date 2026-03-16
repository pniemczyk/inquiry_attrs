# inquiry_attrs — Reserved Predicate Names

## The Problem

Some predicate names are **already defined as real methods** on the objects
`inquiry_attrs` returns. `method_missing` is never reached for these names, so
calling them does **not** test whether the attribute value equals that word —
the existing method is called instead.

## The Reserved Names

| Predicate | Defined by | What it tests | Never tests |
|---|---|---|---|
| `.nil?` | Ruby `Object#nil?` | Whether the object is `nil` (always `false` for present strings, always `true` for blank values) | `value == "nil"` |
| `.blank?` | ActiveSupport `Object#blank?` | Whether the value is blank (nil / "" / whitespace) | `value == "blank"` |
| `.present?` | ActiveSupport `Object#present?` | Opposite of `blank?` | `value == "present"` |
| `.empty?` | Ruby `String#empty?` | Whether the string is `""` | `value == "empty"` |
| `.frozen?` | Ruby `Object#frozen?` | Whether the object is frozen | `value == "frozen"` |

## Worked Examples

### `.nil?` — always about object identity, not string equality

```ruby
order = Order.new(state: 'nil')
order.state.nil?      # => false  ← it is a StringInquirer, not nil
order.state == 'nil'  # => true   ← use this instead
```

```ruby
order = Order.new(state: nil)
order.state.nil?      # => true   ← NilInquiry::INSTANCE is returned
```

### `.blank?` — tests blankness, not string equality

```ruby
order = Order.new(state: 'blank')
order.state.blank?    # => false  ← "blank" is a non-empty string, so not blank
order.state == 'blank'  # => true  ← use this instead

order = Order.new(state: '')
order.state.blank?    # => true   ← empty string is blank
order.state.nil?      # => true   ← NilInquiry is returned for ''
```

### `.present?` — opposite of blank?, not string equality

```ruby
order = Order.new(state: 'present')
order.state.present?    # => true  ← any non-blank string is present
order.state == 'present'  # => true  ← same result here, but don't rely on it
                                      # for other values the results will differ

order = Order.new(state: 'active')
order.state.present?    # => true  ← "active" is present too
order.state == 'present'  # => false  ← correct — different values
```

### `.empty?` — tests `""`, not string equality

```ruby
order = Order.new(state: 'empty')
order.state.empty?    # => false  ← "empty" has 5 chars
order.state == 'empty'  # => true  ← use this instead

order = Order.new(state: '')
order.state.empty?    # => true (via NilInquiry#empty? which returns true)
```

### `.frozen?` — reflects object freeze state

```ruby
order = Order.new(state: 'frozen')
order.state.frozen?    # => true   ← StringInquirer objects are frozen!
order.state == 'frozen'  # => true  ← coincidentally also true, but wrong reason

order = Order.new(state: 'active')
order.state.frozen?    # => true   ← also frozen (StringInquirer is frozen)
order.state == 'frozen'  # => false  ← correct
```

**Important:** `ActiveSupport::StringInquirer` objects are frozen, so `.frozen?`
always returns `true` regardless of the attribute value. Never use `.frozen?` as
a domain predicate.

## The Safe Pattern

When any domain value matches a reserved name, use direct comparison:

```ruby
# ✅ Always reliable — direct string comparison
record.state == 'blank'
record.state == 'present'
record.state == 'nil'
record.state == 'empty'
record.state == 'frozen'

# ❌ Reserved — tests object state, not string equality
record.state.blank?
record.state.present?
record.state.nil?
record.state.empty?
record.state.frozen?
```

## Code Review Checklist

When reviewing code that uses `inquiry_attrs`, flag any predicate call where
the method name matches the table above AND the intent is to test string equality:

```ruby
# 🚩 Flag for review — intent unclear
user.status.blank?
user.status.present?
user.status.nil?

# ✅ Correct — explicit about intent
user.status == 'blank'
user.status == 'present'
user.status.nil?         # ← OK if testing for blank/nil, NOT for value == "nil"
```

## NilInquiry Behaviour for Reserved Names

`NilInquiry::INSTANCE` (returned for blank attributes) has explicit overrides:

```ruby
ni = InquiryAttrs::NilInquiry::INSTANCE
ni.nil?      # => true    (overridden)
ni.blank?    # => true    (overridden)
ni.present?  # => false   (overridden)
ni.empty?    # => true    (overridden)
ni.frozen?   # => true    (it is frozen)
```

Every other `?`-method returns `false` via `method_missing`:

```ruby
ni.active?   # => false
ni.admin?    # => false
ni.blank_state?  # => false  ← note: "blank_state?" is NOT reserved, method_missing handles it
```

## SymbolInquiry Behaviour for Reserved Names

`SymbolInquiry` (returned for Symbol attributes) overrides:

```ruby
si = InquiryAttrs::SymbolInquiry.new(:active)
si.nil?      # => false   (overridden)
si.blank?    # => false   (overridden)
si.present?  # => true    (overridden)
```
