# CLAUDE.md — inquiry_attrs

## Start here

Before writing any code, read these files in order:

1. **@AGENTS.md** — architecture, design decisions, guardrails, test conventions
2. **@llms/overview.md** — class responsibilities and internal design notes
3. **@llms/usage.md** — common patterns and recipes

---

## Project context

| | |
|---|---|
| **Gem name** | `inquiry_attrs` |
| **Type** | Rails gem (Ruby only, no frontend) |
| **Ruby** | ≥ 3.0 |
| **Rails deps** | `activesupport`, `activerecord`, `railties` — all ≥ 7.0 |
| **Test framework** | Minitest (`minitest-reporters`, SpecReporter) |
| **Database** | SQLite in-memory (tests only) |

---

## Running tests

```bash
# Full suite (preferred)
bundle exec rake

# Full suite (explicit)
bundle exec rake test

# Single file
bundle exec ruby -Ilib -Itest test/inquiry_attrs/concern_test.rb

# Single test by name
bundle exec ruby -Ilib -Itest test/inquiry_attrs/concern_test.rb \
  --name test_matching_predicate_returns_true
```

---

## Key files — one-line each

```
lib/inquiry_attrs/nil_inquiry.rb    # NilInquiry::INSTANCE — frozen singleton for blank values
lib/inquiry_attrs/symbol_inquiry.rb # SymbolInquiry < SimpleDelegator — wraps Symbol attrs
lib/inquiry_attrs/concern.rb        # .inquirer macro — instance_method capture pattern
lib/inquiry_attrs/installer.rb      # Installer.install!/uninstall! — file-system logic
lib/inquiry_attrs/railtie.rb        # loads rake tasks into the host Rails app
lib/tasks/inquiry_attrs.rake        # rails inquiry_attrs:install / :uninstall
test/test_helper.rb                 # Minitest setup + SQLite + on_load simulation
```

---

## Code style

Follow **@~/.agent-os/standards/code-style.md** and **@~/.agent-os/standards/best-practices.md**.

Key rules that apply to this gem:

- 2-space indentation, no tabs
- Single quotes for strings; double quotes only for interpolation
- `snake_case` methods/variables, `PascalCase` classes, `UPPER_SNAKE_CASE` constants
- Comment the *why*, not the *what*; never remove existing comments unless removing the associated code
- Keep it simple — fewest lines possible, no over-engineering

---

## Workflow

### Fixing a bug or adding a feature

1. Read **@AGENTS.md** → section "Adding a new feature — checklist"
2. Write the failing test first
3. Implement the fix
4. Run the full suite — must be 0 failures before committing

### Testing the rake task

The rake tasks are thin shells over `InquiryAttrs::Installer`. Test `Installer`
directly — pass a `Dir.mktmpdir` path as `rails_root`. Never stub `Rails.root`.

```ruby
def test_something
  Dir.mktmpdir do |tmpdir|
    root = Pathname.new(tmpdir)
    FileUtils.mkdir_p(root.join('config', 'initializers'))
    result = InquiryAttrs::Installer.install!(root)
    assert_equal :created, result
  end
end
```

### Building the gem

```bash
gem build inquiry_attrs.gemspec
```

---

## Hard rules (from @AGENTS.md)

- **Never** add `ActiveSupport.on_load` back to `lib/inquiry_attrs.rb` — the
  on_load lives only in the generated initializer
- **Never** call `inquirer` before `attr_accessor` in plain Ruby classes
- **Never** broaden the `rescue` in `concern.rb`
- **Never** stub `Rails.root` in tests — use `Installer.install!(tmpdir)` instead

---

## Reserved predicate names — gotcha

Some predicate names are **real methods** on the objects `inquiry_attrs` returns.
They are **never** handled by `method_missing` and do **not** test string equality.

| Predicate | Actual behaviour |
|---|---|
| `.nil?` | Always `false` for present values; always `true` for blank (`NilInquiry`) |
| `.blank?` | Tests blankness (nil / "" / whitespace) — not `value == "blank"` |
| `.present?` | Opposite of `blank?` — not `value == "present"` |
| `.empty?` | `true` only for `""` — not `value == "empty"` |
| `.frozen?` | Reflects the object's freeze state |

**When writing or reviewing code:** if a domain value matches one of the names
above, use direct comparison instead:

```ruby
record.state == 'blank'    # ✅ correct
record.state.blank?        # ❌ tests blankness, not state == "blank"
```

See `README.md` → "⚠️ Reserved predicate names" for the full worked example.
