# frozen_string_literal: true

module InquiryAttrs
  # Wraps a Symbol to provide the same predicate interface as
  # +ActiveSupport::StringInquirer+.
  #
  #   inquiry = SymbolInquiry.new(:active)
  #   inquiry.active?      # => true
  #   inquiry.inactive?    # => false
  #   inquiry == :active   # => true
  #   inquiry == 'active'  # => true
  #   inquiry.is_a?(Symbol) # => true
  #
  class SymbolInquiry < SimpleDelegator
    # @param sym [Symbol]
    # @raise [ArgumentError] if the argument is not a Symbol
    def initialize(sym)
      raise ArgumentError, "Must be a Symbol, got #{sym.class}" unless sym.is_a?(Symbol)

      super(sym.is_a?(SymbolInquiry) ? sym.__getobj__ : sym)
    end

    def method_missing(method_name, *_args, &_block)
      if method_name.to_s.end_with?('?')
        __getobj__.to_s == method_name.to_s.delete_suffix('?')
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.end_with?('?') || super
    end

    # Compares against Symbol, String, or another SymbolInquiry.
    def ==(other)
      case other
      when SymbolInquiry then __getobj__ == other.__getobj__
      when Symbol        then __getobj__ == other
      when String        then __getobj__.to_s == other
      else false
      end
    end

    def is_a?(klass)    = klass == Symbol || super
    alias kind_of? is_a?

    def nil?    = false
    def blank?  = false
    def present? = true
    def to_s    = __getobj__.to_s
    def to_sym  = __getobj__
    def inspect = ":#{__getobj__}"
  end
end
