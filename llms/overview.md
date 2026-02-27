# inquiry_attrs — LLM Context Overview

> Load this file before modifying or extending the gem.

## Purpose

`inquiry_attrs` adds predicate-style inquiry methods to Rails model attributes.
It is a Rails-only gem (depends on ActiveSupport ≥ 7.0 and ActiveRecord ≥ 7.0).

## File map

```
lib/
  inquiry_attrs.rb                 # Entry point — requires everything, fires on_load hook
  inquiry_attrs/
    version.rb                     # VERSION constant
    nil_inquiry.rb                 # NilInquiry::INSTANCE — returned for blank values
    symbol_inquiry.rb              # SymbolInquiry — wraps Symbol attributes
    concern.rb                     # Concern — provides .inquirer class macro
test/
  test_helper.rb                   # Minitest setup, SQLite in-memory AR connection
  inquiry_attrs/
    nil_inquiry_test.rb
    symbol_inquiry_test.rb
    concern_test.rb                # Integration: AR, StoreModel, plain Ruby, Symbol attrs
llms/
  overview.md                      # This file
  usage.md                         # Common patterns and recipes
```

## Public surface

### Auto-include for ActiveRecord

```ruby
# lib/inquiry_attrs.rb
ActiveSupport.on_load(:active_record) do
  include InquiryAttrs::Concern
end
```

This fires once when ActiveRecord is first loaded, so every
`ApplicationRecord` subclass automatically has access to `.inquirer` — no
explicit `include` needed in AR models.

### `InquiryAttrs::Concern` (opt-in for non-AR classes)

```ruby
include InquiryAttrs::Concern   # adds .inquirer class method
```

### `.inquirer(*attrs)` — the only public class-level API

```ruby
inquirer :status                 # wraps :status reader
inquirer :status, :role, :plan   # wraps multiple readers at once
```

## Return type decision table

| Raw value (from original reader) | Return type |
|---|---|
| `nil`, `""`, or any `blank?` value | `InquiryAttrs::NilInquiry::INSTANCE` |
| `Symbol` | `InquiryAttrs::SymbolInquiry.new(raw)` |
| Any other string | `raw.to_s.inquiry` → `ActiveSupport::StringInquirer` |

## Reserved predicate names

Several predicate names are **already defined as real methods** on the returned
objects. `method_missing` is never reached for them, so they **do not** test
whether the raw attribute value equals that word — they invoke the existing method.

| Predicate | Defined by | What it tests |
|---|---|---|
| `nil?` | Ruby `Object` | Whether the object is `nil` — always `false` for present values |
| `blank?` | ActiveSupport | Whether the value is blank (nil / "" / whitespace) |
| `present?` | ActiveSupport | Opposite of `blank?` |
| `empty?` | Ruby `String` / `NilInquiry` | Whether the string is `""` |
| `frozen?` | Ruby `Object` | Whether the object is frozen |

**Code generation rule:** when a model's attribute domain includes values whose
names match the table above (e.g. a `state` column that can hold `"blank"` or
`"nil"`), use direct string comparison — never a predicate:

```ruby
record.state == 'blank'    # ✅ tests string equality
record.state.blank?        # ❌ tests blankness, not state == "blank"
```

## Class responsibilities

### `InquiryAttrs::NilInquiry`

- Frozen singleton (`INSTANCE`)
- `nil?` → `true`; `blank?` → `true`; `empty?` → `true`; `present?` → `false`
- Every `?`-method → `false` via `method_missing` (except the explicit overrides above)
- `== nil`, `== ""`, `== INSTANCE` → `true`
- `is_a?(NilClass)`, `kind_of?(NilClass)`, `instance_of?(NilClass)` → `true`
  (`NilClass` cannot be subclassed; overridden explicitly)
- Implements `to_s`, `to_str`, `inspect`

### `InquiryAttrs::SymbolInquiry < SimpleDelegator`

- Wraps a `Symbol`; raises `ArgumentError` for non-symbols
- Unwraps nested `SymbolInquiry` on init
- Any `?`-method returns `true` iff `sym.to_s == method_name.delete_suffix('?')`
- `==` accepts `Symbol`, `String`, or `SymbolInquiry`
- `is_a?(Symbol)`, `kind_of?(Symbol)`, `instance_of?(Symbol)` → `true`
  (`Symbol` cannot be subclassed; overridden explicitly)
- `nil?` → `false`; `blank?` → `false`; `present?` → `true`

### `InquiryAttrs::Concern`

The `inquirer` class method:

1. Captures the **original** reader with `instance_method(attr)` before
   redefining — this is the critical design choice that makes plain Ruby
   `attr_accessor` and StoreModel work correctly.
2. Defines a new method via `define_method` that calls `original.bind_call(self)`
   to read the raw value.
3. Falls back to `super()` → `self[attr]` → `nil` when no original exists
   (e.g., lazy AR attribute definitions or Dry::Struct).
4. Applies the return type decision table above.

## Why `instance_method` capture instead of `super()`?

When `inquirer :status` is called after `attr_accessor :status`, the new
`define_method` *replaces* the attr_accessor reader. There is then no superclass
method to call via `super()`, which raises `NoMethodError`. Capturing
`instance_method(:status)` before the redefinition avoids this entirely.

For AR models, `ActiveModel::Attributes` pre-defines readers before `inquirer`
is typically called, so `instance_method` finds them too.

## Why `blank?` instead of `nil? || == ""`?

Since this is a Rails-only gem, `blank?` (from ActiveSupport) is always
available. It handles `nil`, `""`, whitespace-only strings, and any object
that defines `blank?`, all in one call.

## Rails conventions used

| Convention | Where used |
|---|---|
| `ActiveSupport::Concern` | `InquiryAttrs::Concern` |
| `ActiveSupport.on_load(:active_record)` | `lib/inquiry_attrs.rb` — auto-include in AR |
| `ActiveSupport::StringInquirer` via `String#inquiry` | `concern.rb` — wraps string values |
| `Object#blank?` | `concern.rb` — nil/blank detection |

## Test setup

- **Framework:** Minitest with `minitest-reporters` (SpecReporter)
- **Database:** SQLite in-memory (`adapter: 'sqlite3', database: ':memory:'`)
- **AR schema:** defined inline in `setup` with `force: true`, dropped in `teardown`
- **Run command:** `bundle exec ruby -Ilib -Itest test/inquiry_attrs/*.rb`
