#!/usr/bin/env ruby
require File.expand_path("../../config/application", __FILE__)
Rails.application.require_environment!

# Create version info
patches = []
Dir[Rails.root.join("data", "*")].each do |dir|
  puts
  puts "Reading version data for #{dir}"
  meta = File.read("#{dir}/iTunesMetadata.plist")

  # Check for binary
  type = :xml
  begin
    meta =~ /^bplist/
  rescue ArgumentError => e
    if e.message =~ /invalid byte sequence/
      type = :binary
    else
      raise
    end
  end

  # And convert
  if type == :binary
    puts "#{dir} appears to have a binary plist, converting"

    `plutil -convert xml1 '#{dir}/iTunesMetadata.plist'`
    meta = File.read("#{dir}/iTunesMetadata.plist")
  end

  compiled = {}

  meta = meta.split("\n")
  meta.each_index do |i|
    line = meta[i]

    if line =~ />bundleVersion</
      compiled[:build] = meta[i + 1].gsub(/<(\/)?(string|date)>/, "").strip.to_i
    elsif line =~ />bundleShortVersionString</
      compiled[:version] = meta[i + 1].gsub(/<(\/)?(string|date)>/, "").strip
    elsif line =~ />purchaseDate</
      compiled[:created_at] = Time.parse(meta[i + 1].gsub(/<(\/)?(string|date)>/, "").strip)
    end
  end

  if compiled[:build].blank? || compiled[:version].blank? || compiled[:created_at].blank?
    puts "WARNING: Failed to parse metadata, only have #{compiled.inspect}"
    exit
  end

  unless GameVersion.where(:version => compiled[:version]).exists?
    patches << compiled
  end
end

patches.sort_by! {|p| p[:build]}

patches.each do |compiled|
  GameVersion.create!(compiled)
  puts "v#{compiled[:version]} -> #{compiled[:build]}, released on #{compiled[:created_at]}"
end

# Resync game data
puts

latest = GameVersion.sort(:build.desc).first

puts "Loading #{latest.version} data"

path = Dir[Rails.root.join("data", "SolForge #{latest.version}", "Payload", "solforge.app", "data", "released", "*.zip")].first
dest = Pathname.new(path.gsub(/\.zip$/, ""))

`unzip -o '#{path}' -d '#{dest}'`

begin
  SyncGameData.new.perform(latest, dest)
ensure
  `rm -rf '#{dest}'`
end

puts "Done"
puts