# frozen_string_literal: true

require_relative 'lib/inquiry_attrs/version'

Gem::Specification.new do |spec|
  spec.name    = 'inquiry_attrs'
  spec.version = InquiryAttrs::VERSION
  spec.authors = ['Pawel Niemczyk']
  spec.email = ['pniemczyk.info@gmail.com']

  spec.summary     = 'Predicate-style inquiry methods for Rails model attributes'
  spec.description = <<~DESC
    InquiryAttrs wraps ActiveRecord/ActiveModel (and StoreModel/Dry::Struct) attributes with
    predicate-style inquiry methods. Write user.status.active? instead of
    user.status == "active". Blank/nil values safely return false for every
    predicate — no more NoMethodError on nil. Run `rails inquiry_attrs:install`
    to generate an initializer that auto-includes the concern into every
    ActiveRecord model.
  DESC

  spec.homepage              = 'https://github.com/pniemczyk/inquiry_attrs'
  spec.license               = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.metadata['homepage_uri']  = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    'lib/**/*.rb',
    'lib/tasks/*.rake',
    'llms/**/*.md',
    'AGENTS.md',
    'CLAUDE.md',
    'README.md',
    'CHANGELOG.md',
    'LICENSE'
  ]

  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 7.0', '< 9'
  spec.add_dependency 'activerecord',  '>= 7.0', '< 9'
  spec.add_dependency 'railties',      '>= 7.0', '< 9'
end
