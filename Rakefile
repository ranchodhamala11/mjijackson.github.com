require 'cgi'
require 'erb'
require 'yaml'
require 'time'
require 'builder'
require 'rdiscount'

SOURCE = '.'
PUBLIC = 'public'
directory PUBLIC
TAG = File.join(PUBLIC, 'tag')
directory TAG

# a list of static assets
ASSETS = %w< css etc CNAME README robots.txt >.map {|f| File.join(SOURCE, f) }
# a map of all URL's to their respective priorities
SITEMAP = { '/' => 1.0, '/about' => 0.5 }
# a map of all tags to the posts that contain that tag
TAG_POSTS = {}
# a map of all years and months to the posts that were published in that time
ARCHIVE = {}
# a list of the names of all individual post files
POST_FILES = []
# a list of the names of all tag/* files
TAG_FILES = []
# a list of the names of all archive files (posts by month and year)
ARCHIVE_FILES = []

class Page
  @dir = File.join(SOURCE, 'pages')

  class << self
    attr_reader :dir

    def all
      @all ||= Dir[File.join(@dir, '*.text')].map {|path| new(path) }
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
    raise ArgumentError, "cannot find file #{path}" unless File.exist?(path)
    @path = path
  end

  def data
    unless @data
      @data = { :body => File.read(@path) }

      if @data[:body] =~ /^-{3}(.+?)-{3}\s*/m
        YAML.load($1).each do |key, value|
          @data[key.to_sym] = value
        end
        # set default author
        @data[:author] ||= 'Michael Jackson'
        # set timestamps
        @data[:published] = @data[:published] ? Time.parse(@data[:published]) : Time.now
        @data[:updated] = @data[:updated] ? Time.parse(@data[:updated]) : @data[:published]
        # default to no tags unless specified
        @data[:tags] ||= []
        # body is the remainder of the file
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

  # the original file extension
  def ext
    @ext ||= File.extname(@path)
  end

  # the file name (or basename - extension)
  def name
    @name ||= File.basename(@path, ext)
  end

  # the mtime of the file
  def mtime
    @mtime ||= File.mtime(@path)
  end

  # the year this page was published as a string
  def year
    published.year.to_s
  end

  # the month this page was published as a string
  def month
    sprintf("%02d", published.month)
  end

  # the day this page was published as a string
  def day
    sprintf("%02d", published.day)
  end

  def to_html
    @html ||= Markdown.new(body, :smart).to_html
  end

  # extract the first paragraph with more than 7 words
  def excerpt
    text = ''
    blocks = to_html.scan(/(<(blockquote|p)>.*?<\/(blockquote|p)>)/m)
    blocks.each do |block|
      text << block[0]
      text << '</blockquote>' unless block[1] == 'p' || block[2] == 'blockquote'
      return text if block[0].split(' ').length > 7
    end
    blocks.first[0]
  end

  def to_s
    "<#{self.class}:#{self.object_id} @name=#{name}>"
  end
end

class Post < Page
  @dir = File.join(SOURCE, 'posts')

  def self.last(n)
    all.sort_by {|post| post.published }.last(n)
  end

  # need to override this method because post files are named with the date
  def name
    @name ||= File.basename(@path, ext).sub(/^\d{4}-\d{2}-\d{2}-/, '')
  end

  # the permanent link to this post, will be in the form of /:year/:month/:name
  def permalink
    @permalink ||= '/' + [year, month, name].join('/')
  end

  # the alternate url for this post
  def alt
    @data[:alt] || permalink
  end

  # if this post is an original, the permalink will be the same as the alternate url
  def is_original?
    !@data.has_key?(:alt)
  end

  # the atom id of this post
  def atom_id
    @id ||= "tag:mjijackson.com," + published.strftime('%Y-%m-%d') + ":" + permalink
  end
end

## Preprocessor ###############################################################

Post.all.each do |post|
  dir = File.join(PUBLIC, post.year, post.month)
  directory dir unless Rake::Task.task_defined?(dir)

  html = File.join(dir, post.name + '.html')
  file html => dir do
    make_post(post, html)
  end
  POST_FILES << html

  # make a plain text version of posts as well
  text = File.join(dir, post.name + '.text')
  file text => dir do
    cp post.path, text
  end
  POST_FILES << text

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
  html = File.join(TAG, CGI.escape(tag) + ".html")
  file html => TAG do
    make_tag(posts, html, tag)
  end
  TAG_FILES << html
  SITEMAP['/tag/' + CGI.escape(tag)] = 0.5
end

ARCHIVE.each do |year, months|
  dir = File.join(PUBLIC, year)
  directory dir
  year_posts = []

  months.each do |month, posts|
    year_posts += posts
    html = File.join(dir, "#{month}.html")
    file html => dir do
      make_archive(posts, html, year, month)
    end
    ARCHIVE_FILES << html
    SITEMAP["/#{year}/#{month}"] = 0.5
  end

  html = File.join(dir, "index.html")
  file html do
    make_archive(year_posts, html, year)
  end
  ARCHIVE_FILES << html
  SITEMAP["/#{year}"] = 0.5
end

## Task Definitions ###########################################################

task :default => :build

desc "Build the entire site"
task :build => [:posts, :tags, :archives, :index, :about, :not_found,
  :feed, :sitemap, :assets]

desc "Build all posts"
task :posts => POST_FILES

desc "Build the tags pages"
task :tags => TAG_FILES

desc "Build the archives"
task :archives => ARCHIVE_FILES

desc "Build the index"
task :index => PUBLIC do
  posts = Post.last(10).reverse
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

def make_post(post, outfile)
  posts = [ post ]
  title = post.title
  make_file(outfile, eval_layouts([:posts, :base], binding))
end

def make_tag(posts, outfile, tag)
  posts = posts.sort_by {|post| post.published }.reverse
  title = "Posts tagged &#8220;#{tag}&#8221;"
  make_file(outfile, eval_layouts([:'posts-excerpts', :tag, :base], binding))
end

def make_archive(posts, outfile, year, month=nil)
  posts = posts.sort_by {|post| post.published }.reverse
  sig = (month ? month_name(month) + ' ' : '') + year
  title = "Posts published in #{sig}"
  make_file(outfile, eval_layouts([:'posts-excerpts', :archive, :base], binding))
end

def month_name(month)
  {
    '01' => 'January',
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
  }[month]
end
