# frozen_string_literal: true

module InquiryAttrs
  # Returned by an inquired attribute when its raw value is blank.
  #
  # Every +?+ predicate returns +false+, so callers never receive a
  # +NoMethodError+ and nil comparisons work naturally.
  #
  #   user.status         # => InquiryAttrs::NilInquiry::INSTANCE  (when nil/blank)
  #   user.status.nil?    # => true
  #   user.status.active? # => false
  #   user.status == nil  # => true
  #
  class NilInquiry
    INSTANCE = new.freeze

    # Any +?+ method returns false — no NoMethodError on blank attributes.
    def method_missing(method_name, *_args, &_block)
      return false if method_name.to_s.end_with?('?')

      super
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.end_with?('?') || super
    end

    def nil? = true
    def blank? = true
    def empty? = true
    def present? = false
    def to_s = ''
    def to_str = ''
    def inspect = 'nil'

    def ==(other)
      other.nil? || other == '' || other.equal?(INSTANCE)
    end
  end
end
