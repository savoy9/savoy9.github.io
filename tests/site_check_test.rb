require "minitest/autorun"
require "tmpdir"
require "fileutils"
require_relative "../scripts/check_site"
require_relative "../_plugins/dax"

class SiteCheckTest < Minitest::Test
  def setup
    @directory = Dir.mktmpdir("notebook-check")
    FileUtils.mkdir_p(File.join(@directory, "Dax-Aggregations"))
    File.write(File.join(@directory, "Dax-Aggregations", "index.html"), '<h1 id="why">Why</h1>')
    @checker = SiteCheck.new(@directory)
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def test_checks_case_sensitive_routes_and_fragments
    @checker.check_reference("/", "/Dax-Aggregations/#why")
    assert_empty @checker.errors
    @checker.check_reference("/", "/dax-aggregations/")
    @checker.check_reference("/", "/Dax-Aggregations/#missing")
    assert_equal 2, @checker.errors.size
    assert_match(/exact case/, @checker.errors.first)
    assert_match(/missing fragment/, @checker.errors.last)
  end

  def test_rejects_missing_assets_and_malformed_relative_links
    @checker.check_reference("/Dax-Aggregations/", "/images/missing.png")
    @checker.check_reference("/Dax-Aggregations/", "radacad.com/article")
    assert_equal 2, @checker.errors.size
  end

  def test_handles_encoded_paths_and_ignores_external_destinations
    File.write(File.join(@directory, "a diagram.svg"), "<svg/>")
    @checker.check_reference("/", "/a%20diagram.svg")
    @checker.check_reference("/", "https://example.com/not-local")
    @checker.check_reference("/", "mailto:alex@example.com")
    assert_empty @checker.errors
  end

  def test_rejects_non_https_local_references
    @checker.check_reference("/", "http://savoy9.github.io/Dax-Aggregations/")
    assert_equal 1, @checker.errors.size
    assert_match(/non-HTTPS/, @checker.errors.first)
  end

  def test_detects_emitted_drafts_even_without_html_front_matter
    FileUtils.mkdir_p(File.join(@directory, "drafts"))
    File.write(File.join(@directory, "drafts", "FeaturedTables.md"), "Not published")
    @checker.check
    assert @checker.errors.any? { |error| error.include?("Source-only or draft file emitted: drafts/FeaturedTables.md") }
  end

  def test_fails_when_build_directory_is_missing
    checker = SiteCheck.new(File.join(@directory, "missing"))
    assert_equal 1, checker.check.size
    assert_match(/Missing site directory/, checker.errors.first)
  end

  def test_dax_highlighting_preserves_table_and_column_names_and_operators
    code = "IF ( ISFILTERED ( 'Fact Sale'[A]]B] ) || [Flag], SUM ( 'Fact Sale'[Total] ), 0 )"
    tokens = Rouge::Lexers::DAX.new.lex(code).to_a
    assert_equal code, tokens.map(&:last).join
    assert tokens.any? { |token, value| token.qualname == "Name.Variable" && value == "[A]]B]" }
    assert tokens.any? { |token, value| token.qualname == "Name.Function" && value == "ISFILTERED" }
    refute tokens.any? { |token, _| token.qualname == "Error" }
  end
end
