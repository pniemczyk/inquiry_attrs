# Changelog

All notable changes to `inquiry_attrs` are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [1.0.2] — 2026-02-27

### Added

- **`NilInquiry#is_a?` / `#kind_of?` / `#instance_of?`** — all three type-check
  methods now return `true` when called with `NilClass` as the argument.
  `NilClass` cannot be subclassed in Ruby, so the methods are overridden
  explicitly (the same technique already used by `SymbolInquiry` for `Symbol`).
  `is_a?(InquiryAttrs::NilInquiry)` continues to return `true`.

- **`SymbolInquiry#kind_of?` / `#instance_of?`** — aliased to the existing
  `is_a?` override so all three type-check methods consistently return `true`
  for `Symbol` and the `SymbolInquiry` class itself.

- **README — ⚠️ Reserved predicate names** — new section documenting that
  attribute values whose names match built-in Ruby/Rails `?`-methods (`nil`,
  `blank`, `present`, `empty`, `frozen`) will invoke the real method rather than
  testing string equality, and explaining the safe `== 'value'` alternative.

---

## [1.0.0] — 2026-02-27

### Added

#### Core

- **`InquiryAttrs::Concern`** — `ActiveSupport::Concern` that adds the
  `.inquirer(*attrs)` class macro to any model. Automatically included into
  `ActiveRecord::Base` via the generated initializer; opt-in for StoreModel
  and plain Ruby classes via explicit `include`.

- **`InquiryAttrs::NilInquiry`** — frozen singleton (`INSTANCE`) returned when
  an inquired attribute is blank. Every `?`-predicate returns `false`; behaves
  like `nil` in comparisons (`== nil`, `== ""`). Eliminates `NoMethodError` on
  nil attributes.

- **`InquiryAttrs::SymbolInquiry`** — `SimpleDelegator` subclass returned when
  an inquired attribute holds a `Symbol`. Predicate methods match against the
  symbol name; compares equal to both `Symbol` and `String`; `is_a?(Symbol)`
  returns `true`.

- **Return-type dispatch in `.inquirer`** — blank → `NilInquiry::INSTANCE`,
  Symbol → `SymbolInquiry`, anything else → `ActiveSupport::StringInquirer`
  (standard `"value".inquiry`).

- **`instance_method` capture pattern** — the original attribute reader is
  captured with `instance_method(attr)` and called via `bind_call` inside the
  wrapper, so `attr_accessor`, StoreModel, and AR readers all work without
  relying on `super()`.

- **`remove_method` before `define_method`** — clears the reader from the
  class's own method table before redefining, silencing Ruby's "method
  redefined" warning that fires when AR/StoreModel define readers via
  `define_method` and `inquirer` overwrites them.

#### Install task

- **`InquiryAttrs::Installer`** — pure Ruby class with `install!(rails_root)`
  and `uninstall!(rails_root)` class methods. Accepts `Pathname` or `String`.
  Returns `:created` / `:skipped` / `:removed` symbols. Testable without Rails
  or Rake by passing a `Dir.mktmpdir` path.

- **`InquiryAttrs::Railtie`** — loaded when `Rails::Railtie` is defined;
  exposes `rails inquiry_attrs:install` and `rails inquiry_attrs:uninstall` to
  the host application via `rake_tasks { load ... }`.

- **`rails inquiry_attrs:install`** — writes
  `config/initializers/inquiry_attrs.rb` containing the
  `ActiveSupport.on_load(:active_record)` block. Skips silently if the file
  already exists.

- **`rails inquiry_attrs:uninstall`** — removes the generated initializer.
  Skips silently if the file is absent.

#### Developer experience

- **`Rakefile`** — `bundle exec rake` / `bundle exec rake test` runs the full
  Minitest suite.

- **LLM context** — `AGENTS.md`, `CLAUDE.md`, `llms/overview.md`,
  `llms/usage.md` shipped inside the gem for AI-assisted development.

### Compatibility

- Ruby ≥ 3.0
- Rails 7.x and 8.x (`activesupport`, `activerecord`, `railties` — `>= 7.0, < 9`)

---

[Unreleased]: https://github.com/pniemczyk/inquiry_attrs/compare/v1.0.2...HEAD
[1.0.2]: https://github.com/pniemczyk/inquiry_attrs/compare/v1.0.0...v1.0.2
[1.0.0]: https://github.com/pniemczyk/inquiry_attrs/releases/tag/v1.0.0
