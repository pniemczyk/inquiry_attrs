# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'pathname'

# Tests for InquiryAttrs::Installer — the class the rake tasks delegate to.
# No Rake DSL or Rails.root stub needed; we pass a tmp dir as rails_root.
class InstallerTest < Minitest::Test
  INITIALIZER_RELATIVE = InquiryAttrs::Installer::INITIALIZER_PATH

  def setup
    @root = Pathname.new(Dir.mktmpdir('inquiry_attrs_installer_test'))
    FileUtils.mkdir_p(@root.join('config', 'initializers'))
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  # ── install! ── #

  def test_install_creates_initializer_and_returns_created
    result = InquiryAttrs::Installer.install!(@root)

    assert_equal :created, result
    assert @root.join(INITIALIZER_RELATIVE).exist?,
           'initializer file should be created'
  end

  def test_install_writes_on_load_block
    InquiryAttrs::Installer.install!(@root)

    content = @root.join(INITIALIZER_RELATIVE).read
    assert_includes content, 'ActiveSupport.on_load(:active_record)'
    assert_includes content, 'include InquiryAttrs::Concern'
  end

  def test_install_writes_frozen_string_literal_comment
    InquiryAttrs::Installer.install!(@root)

    content = @root.join(INITIALIZER_RELATIVE).read
    assert content.start_with?('# frozen_string_literal: true'),
           'initializer should begin with frozen_string_literal magic comment'
  end

  def test_install_writes_generator_attribution_comment
    InquiryAttrs::Installer.install!(@root)

    content = @root.join(INITIALIZER_RELATIVE).read
    assert_includes content, 'rails inquiry_attrs:install'
  end

  def test_install_returns_skipped_when_initializer_exists
    @root.join(INITIALIZER_RELATIVE).write('# existing content')

    result = InquiryAttrs::Installer.install!(@root)

    assert_equal :skipped, result
  end

  def test_install_does_not_overwrite_existing_initializer
    existing = @root.join(INITIALIZER_RELATIVE)
    existing.write('# existing content')

    InquiryAttrs::Installer.install!(@root)

    assert_equal '# existing content', existing.read,
                 'existing initializer must not be overwritten'
  end

  # ── uninstall! ── #

  def test_uninstall_removes_initializer_and_returns_removed
    @root.join(INITIALIZER_RELATIVE).write('# content')

    result = InquiryAttrs::Installer.uninstall!(@root)

    assert_equal :removed, result
    refute @root.join(INITIALIZER_RELATIVE).exist?,
           'initializer file should be deleted'
  end

  def test_uninstall_returns_skipped_when_initializer_absent
    result = InquiryAttrs::Installer.uninstall!(@root)

    assert_equal :skipped, result
  end

  # ── installed content validity ── #

  def test_installed_initializer_is_valid_ruby
    InquiryAttrs::Installer.install!(@root)

    content = @root.join(INITIALIZER_RELATIVE).read
    # RubyVM::InstructionSequence.compile raises SyntaxError for invalid Ruby.
    assert_silent { RubyVM::InstructionSequence.compile(content) }
  end

  def test_installer_accepts_string_path
    root_str = @root.to_s
    result   = InquiryAttrs::Installer.install!(root_str)

    assert_equal :created, result
  end
end
