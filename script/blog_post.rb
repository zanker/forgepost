#!/usr/bin/env ruby
require File.expand_path("../../config/application", __FILE__)
Rails.application.require_environment!

require "readline"
require "rdiscount"

post = Post.new
post.title = Readline.readline("title> ", false).strip
post.slug = post.title.parameterize

puts "Blog content, use ##DONE to finish:"
puts

text = ""
while line = Readline.readline("", false)
  break if line.strip == "##DONE"
  text << line << "\n"
end

post.body = RDiscount.new(text.gsub(":readmore:", ""), :autolink).to_html.strip

if text =~ /(.+):readmore:/m
  post.short_body = RDiscount.new($1, :autolink).to_html.strip
end

puts
puts
puts "TITLE: #{post.title}"

if post.short_body?
  puts "SHORT BODY:"
  puts post.short_body

  puts
  puts "---------------"
  puts
  puts "LONG BODY:"
  puts post.body
else
  puts
  puts "BODY:"
  puts post.body
end

puts
puts

line = Readline.readline("Looks good? [y/N]: ", false)
if line == "y"
  post.save

  if post.valid?
    puts "Post created!"
    Rails.cache.delete("news")

  else
    puts "ERROR"
    puts post.errors.inspect
  end

else
  puts "No post created"
end