#!/usr/bin/env ruby
require 'rubygems'
require 'mechanize'
require 'hpricot'
require 'optparse'

urls = ARGV

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = 'usage: feed.rb [-ar] [-m max] url...'

  opts.on('-a', '--atom', 'Include atom feeds') do
    options[:atom] = true
  end

  opts.on('-m', '--max NUMBER', 'Maximum number of feeds to retrieve per URL') do |max|
    options[:max] = max.to_i
  end

  opts.on('-r', '--rss', 'Include rss feeds') do
    options[:rss] = true
  end
end

begin
  optparse.parse!
rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
  puts e
  puts optparse
  exit 1
end

if ! (options[:atom] || options[:rss])
  options[:atom] = true
  options[:rss] = true
end

urls.each do |url|
  page = Mechanize.new.get(url)
  n = 0
  [:rss,:atom].each do |type|
    if options[type]
      found = page.at("//link[@type='application/#{type}+xml']")
      if found
	found.each do |name,val|
	  if name == "href"
	    puts val if (!options[:max]) || ((n+=1) <= options[:max])
	  end
	end
      end
    end
  end
end
