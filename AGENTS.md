# AGENTS.md — inquiry_attrs

This file is the primary context document for AI agents and LLMs working on
this gem. Read it fully before making any changes.

---

## What this gem does

`inquiry_attrs` adds predicate-style inquiry methods to Rails model attributes.

```ruby
# Without inquiry_attrs
user.status == 'active'

# With inquiry_attrs
user.status.active?   # => true
user.status.inactive? # => false
user.status.nil?      # => true when blank — never raises NoMethodError
```

It is a **Rails-only** gem (depends on `activesupport >= 7`, `activerecord >= 7`,
`railties >= 7`). All Rails APIs (`blank?`, `ActiveSupport::Concern`,
`ActiveSupport.on_load`, `String#inquiry`) are available and should be preferred
over reinventing them.

---

## File map

```
lib/
  inquiry_attrs.rb                  # Entry point — requires everything, loads Railtie
  inquiry_attrs/
    version.rb                      # VERSION = '1.0.0'
    nil_inquiry.rb                  # NilInquiry::INSTANCE — frozen singleton for blank values
    symbol_inquiry.rb               # SymbolInquiry < SimpleDelegator — wraps Symbol attrs
    concern.rb                      # Concern — adds .inquirer class macro
    installer.rb                    # Installer — file-system logic for the rake tasks
    railtie.rb                      # Railtie — wires rake tasks into the host Rails app
  tasks/
    inquiry_attrs.rake              # Shell rake tasks (install / uninstall)

test/
  test_helper.rb                    # Minitest setup + SQLite in-memory AR connection
  inquiry_attrs/
    nil_inquiry_test.rb             # Unit tests for NilInquiry
    symbol_inquiry_test.rb          # Unit tests for SymbolInquiry
    concern_test.rb                 # Integration tests: AR, StoreModel, plain Ruby, Symbol
    install_task_test.rb            # Unit tests for Installer (no Rake machinery needed)

llms/
  overview.md                       # Architecture deep-dive for LLMs
  usage.md                          # Common patterns and recipes

AGENTS.md                           # This file
README.md
CHANGELOG.md
```

---

## How to run tests

```bash
# Full suite (preferred)
bundle exec rake

# Single file
bundle exec ruby -Ilib -Itest test/inquiry_attrs/concern_test.rb

# Single test by name
bundle exec ruby -Ilib -Itest test/inquiry_attrs/concern_test.rb \
  --name test_matching_predicate_returns_true
```

Tests use **Minitest** (`minitest-reporters` with SpecReporter). There is no
Rails application — ActiveRecord is wired directly to an in-memory SQLite
database in `test/test_helper.rb`.

---

## Architecture — the three return types

`.inquirer :attr` overrides the original attribute reader and returns one of:

| Raw value | Return type | Key behaviour |
|---|---|---|
| `nil` or any `blank?` value | `NilInquiry::INSTANCE` | `nil?` true, all predicates false |
| `Symbol` | `SymbolInquiry.new(raw)` | predicate matches symbol name |
| Everything else | `raw.to_s.inquiry` → `ActiveSupport::StringInquirer` | standard Rails inquiry |

---

## Architecture — the `instance_method` capture pattern

This is the **most important** design decision in `concern.rb`:

```ruby
def inquirer(*attrs)
  attrs.each do |attr|
    original = method_defined?(attr) ? instance_method(attr) : nil

    # Remove the method from this class's own table before redefining it to
    # silence Ruby's "method redefined" warning. The original is already
    # safely captured in `original` above.
    remove_method(attr) if instance_methods(false).include?(attr)

    define_method(attr) do
      raw = original ? original.bind_call(self) : super()
      # … return type logic
    end
  end
end
```

**Why capture + remove + redefine:** `inquirer :status` must replace the original
reader. Both AR and StoreModel define their readers via `define_method`; calling
`define_method` again on the same method triggers Ruby's "method redefined"
warning. Calling `remove_method` first clears it from the class's own method
table so the subsequent `define_method` is seen as a fresh definition.
`remove_method` is safe here because it only removes the method from *this*
class, not from superclasses, and the original is already preserved in `original`.

**Consequence:** `inquirer` must always be called **after** the attribute reader
is defined. Violating this order produces a `NoMethodError` in plain Ruby classes
(AR and StoreModel define readers early enough for this not to matter).

---

## Architecture — Railtie / rake task / Installer split

```
Rails app                    inquiry_attrs gem
─────────────────            ──────────────────────────────────────────────────
Gemfile ──requires──▶  lib/inquiry_attrs.rb
                            └── lib/inquiry_attrs/railtie.rb  (only if Rails::Railtie defined)
                                    └── rake_tasks { load 'lib/tasks/inquiry_attrs.rake' }

$ rails inquiry_attrs:install
                       ──▶  task :install
                                └── InquiryAttrs::Installer.install!(Rails.root)
                                        └── writes config/initializers/inquiry_attrs.rb
```

**Why Installer is a separate class:** The rake task calls `Rails.root`, which is
unavailable in tests without a full Rails boot. By pushing all logic into
`Installer.install!(root)`, tests can pass any `Pathname` as the root — no
stubbing, no Rake DSL needed.

**The generated initializer** contains:

```ruby
ActiveSupport.on_load(:active_record) do
  include InquiryAttrs::Concern
end
```

This is the **only** place where `on_load` is used. The gem itself does not
auto-include anything on load — that would be implicit and hard to audit.

---

## Key classes — quick reference

### `NilInquiry` (`lib/inquiry_attrs/nil_inquiry.rb`)

- Frozen singleton: `NilInquiry::INSTANCE`
- `nil?` → `true`; `blank?` → `true`; `present?` → `false`
- Any `?`-method → `false` via `method_missing`
- `== nil`, `== ""`, `== INSTANCE` → `true`
- Implements `to_s` / `to_str` / `inspect`

### `SymbolInquiry` (`lib/inquiry_attrs/symbol_inquiry.rb`)

- Subclasses `SimpleDelegator`, wraps a `Symbol`
- Raises `ArgumentError` for non-Symbol; unwraps nested `SymbolInquiry`
- `?`-method returns `true` iff `sym.to_s == method_name.delete_suffix('?')`
- `==` accepts `Symbol`, `String`, or `SymbolInquiry`
- `is_a?(Symbol)` and `kind_of?(Symbol)` → `true`
- `nil?` → `false`; `blank?` → `false`; `present?` → `true`

### `Concern` (`lib/inquiry_attrs/concern.rb`)

- `extend ActiveSupport::Concern`
- Single class method: `inquirer(*attrs)` — see `instance_method` capture pattern above
- Uses `blank?` (Rails) instead of `nil? || == ""`

### `Installer` (`lib/inquiry_attrs/installer.rb`)

- `Installer::INITIALIZER_PATH` — `Pathname` relative path to the initializer
- `Installer::INITIALIZER_CONTENT` — the exact string written to disk
- `Installer.install!(rails_root)` → `:created` or `:skipped`
- `Installer.uninstall!(rails_root)` → `:removed` or `:skipped`
- Accepts `Pathname` or `String` as `rails_root`

---

## Adding a new feature — checklist

1. **Write the test first** in the appropriate `test/inquiry_attrs/*_test.rb` file.
2. Implement in `lib/inquiry_attrs/`.
3. If the feature touches `Installer` (file operations), test via `InstallerTest`
   passing a `Dir.mktmpdir` path — never stub `Rails.root`.
4. If the feature is a new public API, document it in `llms/overview.md` and
   `llms/usage.md` and update `README.md`.
5. Run the full test suite and confirm 0 failures.
6. Update `CHANGELOG.md`.

---

## Things to never do

| Don't | Why |
|---|---|
| Add `on_load` back to `lib/inquiry_attrs.rb` | Makes the gem implicitly modify every AR model; hard to audit |
| Broaden the `rescue` in `concern.rb` | Swallows real errors in attribute readers |
| Call `inquirer` before `attr_accessor` in plain Ruby | `instance_method` capture returns `nil`; reader will be `nil` |
| Stub `Rails.root` in tests | Use `Installer.install!(tmpdir)` instead |
| Add a dependency on anything outside ActiveSupport/ActiveRecord/Railties | This is a Rails gem; Rails is already the dependency |
| Introduce allocation inside the hot path (e.g. `String.new.extend(...)`) | `NilInquiry::INSTANCE` is a frozen singleton for a reason |

---

## Dependencies

| Gem | Version | Why |
|---|---|---|
| `activesupport` | `>= 7.0` | `Concern`, `blank?`, `String#inquiry`, `on_load` |
| `activerecord` | `>= 7.0` | AR integration (attr readers, `on_load` hook) |
| `railties` | `>= 7.0` | `Rails::Railtie` for exposing rake tasks |
| `sqlite3` | dev only | In-memory DB for AR tests |
| `store_model` | dev only | Integration tests for StoreModel |
| `minitest` + `minitest-reporters` | dev only | Test framework |

---

## Test conventions

- Use `Minitest::Test` (not `ActiveSupport::TestCase`)
- AR schema is created in `setup` with `force: true` and dropped in `teardown`
- `InstallerTest` uses `Dir.mktmpdir` — always clean up in `teardown`
- `assert` / `refute` preferred over `assert_equal true/false`
- Group related tests with comment banners: `# ── install! ── #`
- Test method names describe the exact behaviour: `test_install_skips_when_initializer_already_exists`
