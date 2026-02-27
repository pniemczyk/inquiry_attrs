# frozen_string_literal: true

require 'test_helper'

# ── ActiveRecord ──────────────────────────────────────────────────────────── #

class ActiveRecordInquirerTest < Minitest::Test
  def setup
    ActiveRecord::Schema.define do
      create_table :ar_inquiry_users, force: true do |t|
        t.string :status
        t.string :role
      end
    end

    @model = Class.new(ActiveRecord::Base) do
      self.table_name = 'ar_inquiry_users'
      # No explicit include needed — InquiryAttrs::Concern is auto-included into
      # ActiveRecord::Base via the on_load hook set up in test_helper (simulating
      # what `rails inquiry_attrs:install` puts in config/initializers/).
      inquirer :status, :role
    end
  end

  def teardown
    ActiveRecord::Base.connection.drop_table(:ar_inquiry_users, if_exists: true)
  end

  # ── happy path ── #

  def test_matching_predicate_returns_true
    user = @model.new(status: 'active', role: 'admin')
    assert user.status.active?
    assert user.role.admin?
  end

  def test_non_matching_predicate_returns_false
    user = @model.new(status: 'active', role: 'admin')
    refute user.status.inactive?
    refute user.role.guest?
  end

  def test_compares_equal_to_raw_string
    user = @model.new(status: 'active')
    assert_equal 'active', user.status
  end

  def test_is_not_nil_when_value_is_set
    user = @model.new(status: 'active')
    refute user.status.nil?
  end

  def test_is_not_blank_when_value_is_set
    user = @model.new(status: 'active')
    refute user.status.blank?
  end

  # ── nil attribute ── #

  def test_nil_attribute_returns_nil_inquiry_instance
    user = @model.new(status: nil, role: nil)
    assert_same InquiryAttrs::NilInquiry::INSTANCE, user.status
    assert_same InquiryAttrs::NilInquiry::INSTANCE, user.role
  end

  def test_nil_attribute_nil_predicate_is_true
    assert @model.new(status: nil).status.nil?
  end

  def test_nil_attribute_any_predicate_is_false
    user = @model.new(status: nil)
    refute user.status.active?
    refute user.status.unknown?
  end

  def test_nil_attribute_equals_nil
    assert @model.new(status: nil).status == nil  # rubocop:disable Style/NilComparison
  end

  # ── blank string ── #

  def test_empty_string_returns_nil_inquiry_instance
    user = @model.new(status: '')
    assert_same InquiryAttrs::NilInquiry::INSTANCE, user.status
  end

  def test_empty_string_any_predicate_is_false
    refute @model.new(status: '').status.active?
  end

  # ── multiple attributes ── #

  def test_each_attribute_is_independent
    user = @model.new(status: 'active', role: 'guest')
    assert user.status.active?
    refute user.role.admin?
    assert user.role.guest?
  end
end

# ── StoreModel ────────────────────────────────────────────────────────────── #

class StoreModelInquirerTest < Minitest::Test
  def setup
    @model = Class.new do
      include StoreModel::Model
      include InquiryAttrs::Concern   # explicit include for non-AR classes

      attribute :status, :string
      attribute :role,   :string

      inquirer :status, :role
    end
  end

  def test_matching_predicate_returns_true
    record = @model.new(status: 'pending', role: 'editor')
    assert record.status.pending?
    assert record.role.editor?
  end

  def test_non_matching_predicate_returns_false
    record = @model.new(status: 'pending', role: 'editor')
    refute record.status.active?
    refute record.role.admin?
  end

  def test_compares_equal_to_raw_string
    assert_equal 'pending', @model.new(status: 'pending').status
  end

  def test_nil_attribute_reports_nil
    assert @model.new.status.nil?
  end

  def test_nil_attribute_any_predicate_is_false
    refute @model.new.status.active?
  end
end

# ── Plain Ruby class ──────────────────────────────────────────────────────── #

class PlainRubyInquirerTest < Minitest::Test
  def setup
    @model = Class.new do
      include InquiryAttrs::Concern   # explicit include

      attr_accessor :status, :role

      def initialize(status: nil, role: nil)
        @status = status
        @role   = role
      end

      # inquirer must be declared AFTER attr_accessor
      inquirer :status, :role
    end
  end

  def test_wraps_string_attributes
    record = @model.new(status: 'published', role: 'viewer')
    assert record.status.published?
    assert record.role.viewer?
  end

  def test_nil_attribute_is_nil_inquiry_instance
    record = @model.new
    assert_same InquiryAttrs::NilInquiry::INSTANCE, record.status
  end

  def test_nil_attribute_nil_predicate_is_true
    assert @model.new.status.nil?
  end

  def test_nil_attribute_any_predicate_is_false
    refute @model.new.status.any_predicate?
  end

  def test_compares_equal_to_raw_string
    assert_equal 'published', @model.new(status: 'published').status
  end
end

# ── Symbol attributes ─────────────────────────────────────────────────────── #

class SymbolAttributeInquirerTest < Minitest::Test
  def setup
    @model = Class.new do
      include InquiryAttrs::Concern

      def initialize(status)
        @status = status
      end

      attr_reader :status
      inquirer :status
    end
  end

  def test_symbol_value_returns_symbol_inquiry
    record = @model.new(:active)
    assert_kind_of InquiryAttrs::SymbolInquiry, record.status
    assert record.status.active?
    refute record.status.inactive?
  end

  def test_symbol_inquiry_compares_to_symbol
    record = @model.new(:active)
    assert record.status == :active
  end

  def test_symbol_inquiry_compares_to_string
    record = @model.new(:active)
    assert record.status == 'active'
  end
end
