# encoding: UTF-8

require 'yaml'
require 'time'
require 'cgi'
require 'erb'
require 'builder'
require 'rdiscount'
require 'tilt'

SOURCE = File.expand_path('..', __FILE__)

PUBLIC = File.expand_path('../public', __FILE__)
directory PUBLIC

TAG = File.join(PUBLIC, 'tag')
directory TAG

# A list of static files that should be copied directly.
ASSETS = %w< assets etc CNAME README robots.txt >.map {|f| File.join(SOURCE, f) }
# A map of all URL's to their respective priorities.
SITEMAP = { '/' => 1.0, '/about' => 0.5 }
# A map of all tags to the posts that contain that tag.
TAG_POSTS = {}
# A map of all years and months to the posts that were published in that time.
ARCHIVE = {}
# A list of the names of all individual post files.
POST_FILES = []
# A list of the names of all tag/* files.
TAG_FILES = []
# A list of the names of all archive files (posts by month and year).
ARCHIVE_FILES = []

class Page
  @dir = File.join(SOURCE, 'pages')

  class << self
    attr_reader :dir

    def all
      @all ||= Dir[File.join(@dir, '*.txt')].map {|path| new(path) }
    end

    def find
      all.each do |page|
        return page if yield(page)
      end
      nil
    end
  end

  attr_reader :path

  def initialize(path)
    raise ArgumentError, "Cannot find file: #{path}" unless File.exist?(path)
    @path = path
  end

  def data
    unless @data
      @data = { :body => File.read(@path) }

      if @data[:body] =~ /^-{3}(.+?)-{3}\s*/m
        YAML.load($1).each do |key, value|
          @data[key.to_sym] = value
        end
        @data[:author] ||= 'Michael Jackson'
        # Set timestamps.
        @data[:published] = @data[:published] ? Time.parse(@data[:published]) : Time.now
        @data[:updated] = @data[:updated] ? Time.parse(@data[:updated]) : @data[:published]
        # Default to no tags unless specified.
        @data[:tags] ||= []
        # Body is the remainder of the file.
        @data[:body] = $'
      end
    end

    @data
  end

  def [](key)
    data[key.to_sym]
  end

  def []=(key, value)
    data[key.to_sym] = value
  end

  def method_missing(sym, *args)
    if sym.to_s =~ /(.+)=$/
      self[$1] = args[0] unless args.empty?
    else
      self[sym]
    end
  end

  def ext
    @ext ||= File.extname(@path)
  end

  def name
    @name ||= File.basename(@path, ext)
  end

  def mtime
    @mtime ||= File.mtime(@path)
  end

  def year
    published.year.to_s
  end

  def month
    '%02d' % published.month
  end

  def day
    '%02d' % published.day
  end

  def to_html
    @html ||= Markdown.new(body, :smart).to_html
  end

  # Extract the first paragraph with more than 7 words.
  def excerpt
    text = ''
    blocks = to_html.scan(/(<(blockquote|p)>.*?<\/(blockquote|p)>)/m)
    blocks.each do |b|
      text << b[0]
      text << '</blockquote>' unless b[1] == 'p' || b[2] == 'blockquote'
      return text if b[0].split(' ').length > 7
    end
    blocks.first[0]
  end

  def to_s
    '<%s:%s @name=%s>' % [self.class, object_id, name]
  end
end

class Post < Page
  @dir = File.join(SOURCE, 'posts')

  def self.last(n)
    all.sort_by {|post| post.published }.last(n)
  end

  # Need to override this method because post files are named with the date.
  def name
    @name ||= File.basename(@path, ext).sub(/^\d{4}-\d{2}-\d{2}-/, '')
  end

  # The permanent link to this post, will be in the form of /:year/:month/:name.
  def permalink
    '/%s/%s/%s' % [year, month, name]
  end

  # The alternate URL for this post. Will be the permalink if no alternate URL
  # is explicitly given.
  def alt
    @data[:alt] || permalink
  end

  # If this post is an original, the permalink will be the same as the
  # alternate URL.
  def is_original?
    !@data.has_key?(:alt)
  end

  def atom_id
    'tag:mjijackson.com,%s:%s' % [published.strftime('%Y-%m-%d'), permalink]
  end
end

## Preprocessor ###############################################################

Post.all.each do |post|
  dir = File.join(PUBLIC, post.year, post.month)
  directory dir unless Rake::Task.task_defined?(dir)

  t = file File.join(dir, post.name + '.html') => dir do |t|
    posts = [ post ]
    title = post.title
    make_file(t.name, eval_layouts([:posts, :base], binding))
  end
  POST_FILES << t.name

  # Make a plain text version of posts as well.
  t = file File.join(dir, post.name + '.txt') => dir do |t|
    cp post.path, t.name
  end
  POST_FILES << t.name

  #SITEMAP["/#{post.year}/#{post.month}/#{post.name}"] = 0.5

  post.tags.each do |tag|
    TAG_POSTS[tag] ||= []
    TAG_POSTS[tag] << post
  end

  ARCHIVE[post.year] ||= {}
  ARCHIVE[post.year][post.month] ||= []
  ARCHIVE[post.year][post.month] << post
end

TAG_POSTS.each do |tag, posts|
  t = file File.join(TAG, CGI.escape(tag) + '.html') => TAG do |t|
    posts = posts.sort_by {|post| post.published }.reverse
    title = 'Posts tagged &#8220;%s&#8221;' % tag
    make_file(t.name, eval_layouts([:excerpts, :tag, :base], binding))
  end
  TAG_FILES << t.name
  SITEMAP['/tag/%s' % CGI.escape(tag)] = 0.5
end

ARCHIVE.each do |year, months|
  year_posts = []

  year_dir = File.join(PUBLIC, year)
  directory year_dir

  months.each do |month, posts|
    year_posts += posts

    month_dir = File.join(year_dir, month)
    directory month_dir

    t = file File.join(month_dir, 'index.html') => month_dir do |t|
      make_archive(posts, t.name, year, month)
    end
    ARCHIVE_FILES << t.name
    SITEMAP['/%s/%s' % [year, month]] = 0.5
  end

  t = file File.join(year_dir, 'index.html') => year_dir do |t|
    make_archive(year_posts, t.name, year)
  end
  ARCHIVE_FILES << t.name
  SITEMAP['/%s' % year] = 0.5
end

## Tasks #######################################################################

task :default => :build

desc "Build the entire site"
task :build => %w<
  posts
  tags
  archives
  index
  about
  not_found
  feed
  sitemap
  assets
>.map {|n| n.to_sym }

desc "Build all posts"
task :posts => POST_FILES

desc "Build the tags pages"
task :tags => TAG_FILES

desc "Build the archives"
task :archives => ARCHIVE_FILES

desc "Build the index"
task :index => PUBLIC do
  posts = Post.last(4).reverse
  make_file(File.join(PUBLIC, 'index.html'), eval_layouts([:posts, :base], binding))
end

desc "Build the about page"
task :about => PUBLIC do
  page = Page.find {|page| page.name == "about" }
  nav = :about
  title = 'About'
  make_file(File.join(PUBLIC, 'about.html'), eval_layouts([:page, :base], binding))
end

desc "Build the 404 page"
task :not_found => PUBLIC do
  page = Page.find {|page| page.name == "404" }
  title = 'Not Found'
  make_file(File.join(PUBLIC, '404.html'), eval_layouts([:page, :base], binding))
end

desc "Build the feed"
task :feed => PUBLIC do
  posts = Post.last(10).reverse
  xml = ::Builder::XmlMarkup.new(:indent => 2)
  file = layout('feed', 'builder')
  eval file, binding, '<EVAL>', 1
  make_file(File.join(PUBLIC, 'index.xml'), xml.target!)
end

desc "Build the sitemap"
task :sitemap => PUBLIC do
  map = SITEMAP
  xml = ::Builder::XmlMarkup.new(:indent => 2)
  file = layout('sitemap', 'builder')
  eval file, binding, '<EVAL>', 1
  make_file(File.join(PUBLIC, 'sitemap.xml'), xml.target!)
end

desc "Copy all static assets"
task :assets => PUBLIC do
  ASSETS.each do |file|
    cp_r file, PUBLIC
  end
end

## Utility Functions ##########################################################

def layout(name, ext="erb")
  layout_file = File.join(SOURCE, 'layouts', "#{name}.#{ext}")
  raise ArgumentError unless File.exist?(layout_file)
  File.read(layout_file)
end

def eval_layouts(layouts, binding)
  result = eval "result", binding rescue ""
  layouts.each do |name|
    eval "result = #{result.to_s.inspect}", binding, '<EVAL>', 1
    result = ERB.new(layout(name), 0, '%<>').result(binding)
  end
  result
end

def make_file(file, contents)
  File.open(file, 'w') {|f| f.write contents }
end

def make_archive(posts, outfile, year, month=nil)
  posts = posts.sort_by {|post| post.published }.reverse
  sig = (month ? month_name(month) + ' ' : '') + year
  title = 'Posts published in %s' % sig
  make_file(outfile, eval_layouts([:excerpts, :archive, :base], binding))
end

def month_name(month)
  { '01' => 'January',
    '02' => 'February',
    '03' => 'March',
    '04' => 'April',
    '05' => 'May',
    '06' => 'June',
    '07' => 'July',
    '08' => 'August',
    '09' => 'September',
    '10' => 'October',
    '11' => 'November',
    '12' => 'December'
  }[month.to_s]
end
