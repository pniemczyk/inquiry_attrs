# inquiry_attrs — Installation Guide

## Requirements

- Ruby ≥ 3.0
- Rails 7.x or 8.x (`activesupport`, `activerecord`, `railties` ≥ 7.0, < 9)

## Step 1: Add to Gemfile

```ruby
# Gemfile
gem 'inquiry_attrs'
```

```bash
bundle install
```

## Step 2: Generate the Initializer

Run the provided rake task from inside the Rails app:

```bash
rails inquiry_attrs:install
```

This writes `config/initializers/inquiry_attrs.rb` with the following content:

```ruby
# frozen_string_literal: true

ActiveSupport.on_load(:active_record) do
  include InquiryAttrs::Concern
end
```

The `on_load` callback fires once when ActiveRecord is first loaded. Every
`ApplicationRecord` subclass automatically has `.inquirer` available — no
manual `include` in individual models.

**The task is idempotent:** running it again when the file already exists
prints a skip message and leaves the file unchanged.

## Step 3: Use `.inquirer` in any model

```ruby
class User < ApplicationRecord
  inquirer :status, :role, :plan
end
```

That's all that's needed for AR models.

## Uninstalling

```bash
rails inquiry_attrs:uninstall
```

Removes `config/initializers/inquiry_attrs.rb`. Idempotent — safe to run
when the file is already absent.

## Manual Include (StoreModel / Plain Ruby)

For classes that do not inherit from `ActiveRecord::Base`, include the concern
explicitly:

```ruby
class ShippingAddress
  include StoreModel::Model
  include InquiryAttrs::Concern   # ← required

  attribute :kind, :string
  inquirer  :kind
end

class Subscription
  include InquiryAttrs::Concern   # ← required

  attr_accessor :plan
  inquirer :plan
end
```

## Verifying the Installation

Open a Rails console and check:

```ruby
# Check the initializer was loaded
InquiryAttrs::Concern                         # should not raise NameError
ActiveRecord::Base.ancestors.include?(InquiryAttrs::Concern)  # => true

# Quick smoke test
class Tmp < ApplicationRecord; self.table_name = 'users'; inquirer :status; end
Tmp.new(status: 'active').status.active?      # => true
Tmp.new(status: nil).status.nil?              # => true
```

## Troubleshooting

**`NoMethodError: undefined method 'inquirer'` in a plain Ruby class**
→ Add `include InquiryAttrs::Concern` before calling `inquirer`.

**`NoMethodError` when calling `inquirer :attr` before `attr_accessor :attr`**
→ Always define the reader first, then call `inquirer`. The macro captures
the original reader at call time.

**The initializer file already exists after `rails inquiry_attrs:install`**
→ That is expected — the task skips silently. The existing file is intact.

**Predicates return unexpected results for values like `"blank"` or `"present"`**
→ See `reserved-predicates.md`. Use `== 'blank'` instead of `.blank?`.
