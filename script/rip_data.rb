#!/usr/bin/env ruby
require File.expand_path("../../config/application", __FILE__)
Rails.application.require_environment!

Dir["/Users/zanker/Music/iTunes/Mobile Applications/*.ipa"].each do |file|
  name = File.basename(file, ".ipa")
  next unless name =~ /Solforge/i

  dest = Rails.root.join("data", name)
  if Dir.exists?(dest)
    puts "Already have #{dest}, no new data found"
    break
  end

  puts "Extracting #{dest}"
  `unzip '#{file}' -d '#{dest}'`

  break
end
