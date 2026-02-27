# frozen_string_literal: true

require 'test_helper'

class NilInquiryTest < Minitest::Test
  def setup
    @instance = InquiryAttrs::NilInquiry::INSTANCE
  end

  # ── predicate methods ────────────────────────────────────────────────────── #

  def test_any_predicate_returns_false
    assert_equal false, @instance.active?
    assert_equal false, @instance.inactive?
    assert_equal false, @instance.anything_at_all?
  end

  def test_responds_to_any_predicate
    assert @instance.respond_to?(:active?)
    assert @instance.respond_to?(:some_totally_unknown_state?)
  end

  def test_non_predicate_unknown_method_raises
    assert_raises(NoMethodError) { @instance.some_method }
  end

  # ── nil / blank semantics ────────────────────────────────────────────────── #

  def test_nil_predicate_is_true
    assert @instance.nil?
  end

  def test_blank_and_empty
    assert @instance.blank?
    assert @instance.empty?
  end

  def test_not_present
    refute @instance.present?
  end

  # ── string representation ────────────────────────────────────────────────── #

  def test_to_s_is_empty_string
    assert_equal '', @instance.to_s
  end

  def test_to_str_for_string_coercion
    assert_equal '', @instance.to_str
  end

  # ── equality ─────────────────────────────────────────────────────────────── #

  def test_equals_nil
    assert @instance == nil  # rubocop:disable Style/NilComparison
  end

  def test_equals_empty_string
    assert @instance == ''
  end

  def test_equals_itself
    assert @instance == InquiryAttrs::NilInquiry::INSTANCE
  end

  def test_does_not_equal_non_blank_value
    refute @instance == 'active'
    refute @instance == :active
  end

  # ── singleton guarantee ──────────────────────────────────────────────────── #

  def test_instance_is_frozen
    assert @instance.frozen?
  end

  def test_instance_is_always_the_same_object
    assert_same InquiryAttrs::NilInquiry::INSTANCE,
                InquiryAttrs::NilInquiry::INSTANCE
  end
end
