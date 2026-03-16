# frozen_string_literal: true

# Example: Testing models that use inquiry_attrs
# Works with both Minitest and RSpec.

# ─── Minitest ──────────────────────────────────────────────────────────────────

require 'minitest/autorun'

class UserInquiryTest < Minitest::Test
  # Predicate — matching value
  def test_status_active_predicate
    user = User.new(status: 'active')
    assert user.status.active?
    refute user.status.suspended?
  end

  # Predicate — non-matching value
  def test_status_suspended_predicate
    user = User.new(status: 'suspended')
    assert user.status.suspended?
    refute user.status.active?
  end

  # Nil/blank safety
  def test_nil_status_is_safe
    user = User.new(status: nil)
    assert user.status.nil?
    refute user.status.active?
    assert_equal nil, user.status
  end

  # Blank string treated like nil
  def test_blank_status_is_nil
    user = User.new(status: '')
    assert user.status.nil?
  end

  # String equality still works
  def test_string_comparison_intact
    user = User.new(status: 'active')
    assert_equal 'active', user.status
    assert user.status == 'active'
    assert user.status.include?('act')
    assert_equal 'ACTIVE', user.status.upcase
  end

  # Multiple attrs
  def test_role_predicate
    user = User.new(role: 'admin')
    assert user.role.admin?
    refute user.role.viewer?
  end
end

# ─── RSpec ─────────────────────────────────────────────────────────────────────

# frozen_string_literal: true

RSpec.describe User do
  describe '#status' do
    context 'when active' do
      subject(:user) { build(:user, status: 'active') }

      it 'returns true for active?' do
        expect(user.status.active?).to be true
      end

      it 'returns false for other predicates' do
        expect(user.status.suspended?).to be false
        expect(user.status.inactive?).to be false
      end

      it 'preserves string behaviour' do
        expect(user.status).to eq('active')
        expect(user.status.upcase).to eq('ACTIVE')
      end
    end

    context 'when nil' do
      subject(:user) { build(:user, status: nil) }

      it 'returns nil? true' do
        expect(user.status.nil?).to be true
      end

      it 'returns false for all domain predicates' do
        expect(user.status.active?).to be false
        expect(user.status.suspended?).to be false
      end

      it 'compares equal to nil' do
        expect(user.status).to eq(nil)
      end
    end

    context 'when blank string' do
      subject(:user) { build(:user, status: '') }

      it 'behaves like nil' do
        expect(user.status.nil?).to be true
        expect(user.status.active?).to be false
      end
    end
  end
end

# ─── Testing Installer (no Rails, no Rake) ─────────────────────────────────────

class InstallerTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @root   = Pathname.new(@tmpdir)
    FileUtils.mkdir_p(@root.join('config', 'initializers'))
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_install_creates_initializer
    result = InquiryAttrs::Installer.install!(@root)
    assert_equal :created, result
    assert @root.join('config/initializers/inquiry_attrs.rb').exist?
  end

  def test_install_skips_when_already_present
    InquiryAttrs::Installer.install!(@root)
    result = InquiryAttrs::Installer.install!(@root)
    assert_equal :skipped, result
  end

  def test_uninstall_removes_initializer
    InquiryAttrs::Installer.install!(@root)
    result = InquiryAttrs::Installer.uninstall!(@root)
    assert_equal :removed, result
    refute @root.join('config/initializers/inquiry_attrs.rb').exist?
  end
end
