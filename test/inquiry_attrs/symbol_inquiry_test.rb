# frozen_string_literal: true

require 'test_helper'

class SymbolInquiryTest < Minitest::Test
  def setup
    @inquiry = InquiryAttrs::SymbolInquiry.new(:active)
  end

  # ── initialization ───────────────────────────────────────────────────────── #

  def test_accepts_symbol
    assert InquiryAttrs::SymbolInquiry.new(:active)
  end

  def test_raises_for_string
    assert_raises(ArgumentError) { InquiryAttrs::SymbolInquiry.new('active') }
  end

  def test_raises_for_nil
    assert_raises(ArgumentError) { InquiryAttrs::SymbolInquiry.new(nil) }
  end

  def test_raises_for_integer
    assert_raises(ArgumentError) { InquiryAttrs::SymbolInquiry.new(1) }
  end

  def test_unwraps_nested_symbol_inquiry
    nested = InquiryAttrs::SymbolInquiry.new(:active)
    outer  = InquiryAttrs::SymbolInquiry.new(nested)
    assert_equal :active, outer.__getobj__
  end

  # ── predicate methods ────────────────────────────────────────────────────── #

  def test_matching_predicate_returns_true
    assert @inquiry.active?
  end

  def test_non_matching_predicate_returns_false
    refute @inquiry.inactive?
    refute @inquiry.pending?
  end

  def test_responds_to_any_predicate
    assert @inquiry.respond_to?(:active?)
    assert @inquiry.respond_to?(:arbitrary_state?)
  end

  def test_non_predicate_unknown_method_raises
    assert_raises(NoMethodError) { @inquiry.unknown_method }
  end

  # ── equality ─────────────────────────────────────────────────────────────── #

  def test_equals_same_symbol
    assert @inquiry == :active
  end

  def test_equals_equivalent_string
    assert @inquiry == 'active'
  end

  def test_equals_another_symbol_inquiry_for_same_symbol
    assert @inquiry == InquiryAttrs::SymbolInquiry.new(:active)
  end

  def test_does_not_equal_different_symbol
    refute @inquiry == :inactive
  end

  def test_does_not_equal_unrelated_object
    refute @inquiry == 42
  end

  # ── type checks ──────────────────────────────────────────────────────────── #

  def test_is_a_symbol
    assert @inquiry.is_a?(Symbol)
    assert @inquiry.kind_of?(Symbol)
  end

  def test_is_a_symbol_inquiry
    assert @inquiry.is_a?(InquiryAttrs::SymbolInquiry)
  end

  # ── conversion ───────────────────────────────────────────────────────────── #

  def test_to_s_returns_string_form
    assert_equal 'active', @inquiry.to_s
  end

  def test_to_sym_returns_original_symbol
    assert_equal :active, @inquiry.to_sym
    assert_kind_of Symbol, @inquiry.to_sym
  end

  def test_inspect_renders_as_symbol_literal
    assert_equal ':active', @inquiry.inspect
  end

  # ── nil / blank semantics ────────────────────────────────────────────────── #

  def test_nil_is_false
    refute @inquiry.nil?
  end

  def test_blank_is_false
    refute @inquiry.blank?
  end

  def test_present_is_true
    assert @inquiry.present?
  end
end
