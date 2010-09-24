#!/usr/bin/env ruby
#
# Add a feed subscription to an OPML file
#
require "optparse"
require "rubygems"
require "nokogiri"
require "mechanize"

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = 'usage: opmlsub.rb -s URL [-i TEXT] FILE...'

  opts.on('-i', '--inside TEXT', 'Text of OPML entry to add this to (default = top)') do |text|
    options[:inside] = text
  end

  opts.on('-s', '--subscribe URL', 'URL of site to subscribe') do |url|
    options[:subscribe] = url
  end
end

begin
  optparse.parse!
  raise OptionParser::MissingArgument.new("-s required") if !options[:subscribe]
rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
  puts e
  puts optparse
  exit 1
end

opml = Nokogiri::XML::parse $<.read
page = Nokogiri::parse Mechanize.new.get(feed = options[:subscribe]).body
if page.at("/html")
  feed = nil
  [:rss,:atom].each do |type|
    if !feed
      found = page.at("//link[@type='application/#{type}+xml']")
      feed = found[:href] if found
    end
  end
  if !feed
    $stderr.puts "opmlsub.rb: #{options[:subscribe]} does not list any feeds"
    exit 2
  end
  feedpage = Mechanize.new.get(feed).body
  page = Nokogiri::XML::parse feedpage
end

if channel = page.at("/rss/channel")	# RSS 2.0
  link = channel.at("link").content
  descr = channel.at("description")
else
  if channel = page.at("feed")		# ATOM
    link = channel.at("link")[:href]
    descr = channel.at("subtitle")
  else
    $stderr.puts "opmlsub.rb: #{feed} does not refer to an RSS 2.0 or ATOM feed"
    exit 3
  end
end

title = channel.at("title").content
descr = descr ? descr.content.gsub(/[\n\r\v]/m , ' '): ' '

parent = opml.at("//outline[@text='#{options[:inside]}']") ||
  	 opml.at("//outline[@text='#{options[:inside]}']") ||
	 opml.at("/opml/body")	# root level, by default

if !parent
  $stderr.puts "opmlsub.rb: #{options[:opml]} not valid OPML"
  exit 4
end

Nokogiri::XML::Builder::with parent do |xml|
  xml.outline(:title => title, :text => title, :description => descr, :htmlUrl => link, :xmlUrl => feed)
end

puts opml.to_xml
