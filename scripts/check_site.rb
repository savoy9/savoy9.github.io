require "nokogiri"
require "pathname"
require "uri"

class SiteCheck
  ORIGIN = "https://savoy9.github.io"
  QUERY_REDUCTION = "/rayfin-performance-query-reduction/"
  OLD_QUERY_REDUCTION = "/same-model-different-workload/"
  ARCHIVED = ["/Dax-Aggregations/", "/Dax-Aggregations-Part-2/"].freeze
  PUBLISHED = {
    "/" => nil,
    "/about/" => nil,
    "/Dax-Aggregations/" => "2019-02-17",
    "/Dax-Aggregations-Part-2/" => "2019-02-19",
    QUERY_REDUCTION => "2026-11-20",
    "/404.html" => nil
  }.freeze
  DRAFT_NAMES = %w[
    Azure-Arch-Diagram-Nuance
    An-Organizational-Implementation-of-the-Power-BI-Pixel-for-Report-Usage-Tracking
    FeaturedTables
  ].freeze

  attr_reader :errors

  def initialize(root)
    @root = Pathname(root).expand_path
    @errors = []
    @documents = {}
  end

  def check
    unless @root.directory?
      errors << "Missing site directory: #{@root}"
      return errors
    end
    files = @root.glob("**/*").select(&:file?)
    files.each do |file|
      relative = file.relative_path_from(@root).to_s
      if relative.match?(%r{(?:\A|/)(?:_?drafts|scripts|tests|vendor)(?:/|\z)}) ||
          DRAFT_NAMES.any? { |name| relative.include?(name) } ||
          relative.match?(/\.(?:md|rb|ya?ml|lock)\z/) ||
          %w[Gemfile README.md LICENSE].include?(relative)
        errors << "Source-only or draft file emitted: #{relative}"
      end
    end
    html_files = files.select { |file| file.extname == ".html" }
    errors << "No generated HTML found" if html_files.empty?
    html_files.each { |file| check_html(file) }
    PUBLISHED.each do |route, date|
      file = resolve(route)
      unless file
        errors << "Missing preserved route (case-sensitive): #{route}"
        next
      end
      next unless date

      document = document(file)
      expect(document.at_css(".article-meta time")&.[]("datetime") == date, route, "original publication date changed")
      expect(document.at_css('meta[property="article:published_time"]')&.[]("content")&.start_with?(date), route, "publication metadata changed")
      next unless ARCHIVED.include?(route)

      expect(document.at_css(".archive-notice")&.text&.include?("not been technically re-reviewed"), route, "archive status missing")
      expect(document.css("pre code").any?, route, "DAX examples missing")
      expect(document.css("pre code .nf").any?, route, "DAX syntax highlighting missing")
      expect(document.at_css(".series-nav a"), route, "series navigation missing")
    end
    expect(resolve(OLD_QUERY_REDUCTION), OLD_QUERY_REDUCTION, "legacy redirect missing")
    check_xml("sitemap.xml", "//xmlns:loc", "http://www.sitemaps.org/schemas/sitemap/0.9")
    check_xml("feed.xml", "//xmlns:link[@href]", "http://www.w3.org/2005/Atom", attribute: "href")
    errors
  end

  # Resolve using directory entries so case errors also fail on Windows/macOS.
  def resolve(path)
    decoded = URI::DEFAULT_PARSER.unescape(path)
    parts = decoded.split("/").reject(&:empty?)
    return nil if parts.include?("..")

    current = @root
    parts.each do |part|
      return nil unless current.directory? && current.children.any? { |child| child.basename.to_s == part }

      current = current.join(part)
    end
    current = current.join("index.html") if current.directory?
    return nil unless current.file? && current.parent.children.any? { |child| child.basename.to_s == current.basename.to_s }

    current
  end

  def document(file)
    @documents[file.to_s] ||= Nokogiri::HTML5(file.read)
  end

  def expect(condition, source, message)
    errors << "#{source}: #{message}" unless condition
  end

  def route_for(file)
    path = "/" + file.relative_path_from(@root).to_s.tr("\\", "/")
    path.sub(%r{index\.html\z}, "")
  end

  def check_html(file)
    route = route_for(file)
    doc = document(file)
    expect(doc.at_css("html")&.[]("lang") == "en", route, "document language missing")
    expect(!doc.at_css("title")&.text.to_s.strip.empty?, route, "title missing")
    check_content(route, doc, file)
    # Standalone interactive figures embedded by posts are not site pages.
    return if route.start_with?("/images/")
    return check_query_reduction_redirect(route, doc) if route == OLD_QUERY_REDUCTION

    expect(doc.css("h1").size == 1, route, "expected exactly one H1")
    expect(doc.css("main#main").size == 1 && doc.at_css('a[href="#main"]'), route, "skip-link target missing")
    expect(!doc.at_css('meta[name="description"]')&.[]("content").to_s.strip.empty?, route, "description missing")
    expect(doc.at_css('link[rel="canonical"]')&.[]("href") == ORIGIN + route, route, "incorrect HTTPS canonical")
    expect(doc.at_css('meta[property="og:url"]')&.[]("content") == ORIGIN + route, route, "incorrect social URL")
    %w[og:title og:description og:image og:image:alt].each do |property|
      expect(!doc.at_css("meta[property='#{property}']")&.[]("content").to_s.empty?, route, "#{property} missing")
    end
    image = doc.at_css('meta[property="og:image"]')&.[]("content")
    expect(image&.start_with?(ORIGIN + "/"), route, "social image must use HTTPS site origin")
    check_reference(route, image) if image
    expect(doc.at_css('meta[name="twitter:card"]'), route, "social card missing")
    viewport = doc.at_css('meta[name="viewport"]')&.[]("content").to_s
    expect(!viewport.include?("maximum-scale") && !viewport.include?("user-scalable=no"), route, "zoom restricted")
    if route == "/"
      PUBLISHED.select { |_, date| date }.each_key do |post|
        expect(doc.css("a").any? { |link| link["href"] == post }, route, "published article not discoverable: #{post}")
      end
    end
  end

  def check_query_reduction_redirect(route, doc)
    expect(doc.at_css('link[rel="canonical"]')&.[]("href") == ORIGIN + QUERY_REDUCTION, route, "incorrect redirect canonical")
    expect(doc.at_css('meta[http-equiv="refresh"]')&.[]("content") == "0; url=#{QUERY_REDUCTION}", route, "incorrect redirect target")
    expect(doc.at_css("body a")&.[]("href") == QUERY_REDUCTION, route, "redirect fallback link missing")
  end

  def check_content(route, doc, file)
    expect(!file.read.match?(/analytics\.js|UA-\d|google-analytics\.com/), route, "obsolete analytics emitted")
    doc.css("img").each { |img| expect(!img["alt"].to_s.strip.empty?, route, "image alt text missing") }
    doc.css("a").each { |link| expect(!(link["aria-label"] || link.text).strip.empty? || link.at_css("img[alt]"), route, "unnamed link") }
    doc.css("[href], [src], [srcset]").each do |node|
      %w[href src].each { |attr| check_reference(route, node[attr]) if node[attr] }
      node["srcset"]&.split(",")&.each { |entry| check_reference(route, entry.strip.split.first) }
    end
  end

  def check_reference(source, reference)
    return if reference.nil? || reference.empty?

    uri = URI.join(ORIGIN + source, reference)
    return if %w[mailto tel].include?(uri.scheme)
    unless %w[http https].include?(uri.scheme)
      errors << "#{source}: unsupported link scheme: #{reference}"
      return
    end
    return unless uri.host == URI(ORIGIN).host

    expect(uri.scheme == "https", source, "non-HTTPS site reference: #{reference}")
    target = resolve(uri.path)
    unless target
      errors << "#{source}: broken internal link/asset (exact case): #{reference}"
      return
    end
    return if uri.fragment.nil? || uri.fragment.empty? || target.extname != ".html"

    fragment = URI::DEFAULT_PARSER.unescape(uri.fragment)
    expect(document(target).css("[id], a[name]").any? { |node| node["id"] == fragment || node["name"] == fragment },
      source, "missing fragment: #{reference}")
  rescue URI::InvalidURIError => error
    errors << "#{source}: invalid URL #{reference.inspect}: #{error.message}"
  end

  def check_xml(name, selector, namespace, attribute: nil)
    file = @root.join(name)
    unless file.file?
      errors << "Missing #{name}"
      return
    end
    xml = Nokogiri::XML(file.read) { |config| config.strict.nonet }
    nodes = xml.xpath(selector, "xmlns" => namespace)
    expect(!nodes.empty?, name, "no publication URLs found")
    urls = nodes.map { |node| attribute ? node[attribute] : node.text }
    expect(!urls.include?(ORIGIN + OLD_QUERY_REDUCTION), name, "legacy redirect listed as published content")
    urls.each do |url|
      expect(url.start_with?(ORIGIN + "/"), name, "incorrect publication origin: #{url}")
      expect(!DRAFT_NAMES.any? { |draft| url.include?(draft) } && !url.include?("/drafts/") && !url.include?("/_drafts/"), name, "draft URL emitted")
      check_reference("/" + name, url)
    end
    required = name == "sitemap.xml" ? PUBLISHED.keys - ["/404.html"] : PUBLISHED.select { |_, date| date }.keys
    required.each { |route| expect(urls.include?(ORIGIN + route), name, "missing published URL: #{route}") }
    return unless name == "feed.xml"

    PUBLISHED.each do |route, date|
      next unless date

      entry = xml.xpath("//xmlns:entry", "xmlns" => namespace).find do |node|
        node.at_xpath("xmlns:link[@rel='alternate']", "xmlns" => namespace)&.[]("href") == ORIGIN + route
      end
      expect(entry&.at_xpath("xmlns:published", "xmlns" => namespace)&.text&.start_with?(date), name, "original feed date changed: #{route}")
    end
  rescue Nokogiri::XML::SyntaxError => error
    errors << "#{name}: invalid XML: #{error.message}"
  end
end

if $PROGRAM_NAME == __FILE__
  checker = SiteCheck.new(ARGV.fetch(0, "_site"))
  errors = checker.check
  if errors.empty?
    puts "Site checks passed: links/assets, drafts, metadata, routes, original dates, feed and sitemap."
  else
    warn errors.join("\n")
    abort "#{errors.size} site check(s) failed."
  end
end
