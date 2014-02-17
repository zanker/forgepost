require File.expand_path("../../config/application", __FILE__)
Rails.application.require_environment!

require "rmagick"
require "fileutils"

IMAGE_SIZES = {
  :rarities => [["large", 140], ["medium", 70], ["small", 35], ["tiny", 20]],
  :cards => [["large", 420], ["medium", 210], ["small", 105], ["tiny", 40]],
  :borders => [["large", 700], ["medium", 350], ["small", 175]],
  :status => [["large", 140], ["medium", 70], ["small", 35], ["tiny", 20]],
  :currencies => [["small", 30]]
}

$changed_files = []

# Conversion
def convert_images(type, files)
  files.delete_if {|f| f.blank?}
  files = Hash[files]

  puts
  puts "Converting #{type} (#{files.length} images)"

  # Directories
  IMAGE_SIZES[type].each do |storage_type, size|
    FileUtils.mkdir_p(Rails.root.join("app", "assets", "images", type.to_s, storage_type)) rescue nil
  end

  # Check originals for changes and setup the manifest file
  FileUtils.mkdir_p(Rails.root.join("app", "assets", "images", type.to_s, "original")) rescue nil

  manifest_path = Rails.root.join("app", "assets", "images", type.to_s, "manifest.yaml")
  manifest = YAML::load_file(manifest_path) rescue {}

  files.each do |source_path, dest_name|
    contents = File.read(source_path)

    # Check for change
    hash = Digest::SHA1.hexdigest(contents)
    if manifest[dest_name] == hash
      files.delete(source_path)
      next
    end

    # Copy original over
    dest_path = Rails.root.join("app", "assets", "images", type.to_s, "original", dest_name)

    File.open(dest_path, "wb+") do |f|
      f.write(contents)
    end

    # Keep log
    manifest[dest_name] = hash
    $changed_files << dest_path
  end

  # Write out the new manifest
  File.open(manifest_path, "w+") do |f|
    f.write(manifest.to_yaml)
  end

  if files.empty?
    puts "No image changes detected"
    return
  end

  # Conversion
  IMAGE_SIZES[type].each do |storage_type, size|
    puts
    puts "Converting #{storage_type}"

    files.each do |source_path, dest_name|
      dest_path = Rails.root.join("app", "assets", "images", type.to_s, storage_type, dest_name)
      $changed_files << dest_path

      puts "#{source_path} -> #{dest_path}"

      image = Magick::Image.read(source_path).first
      image.change_geometry!("#{size}x") do |cols, rows, img|
        new = image.resize(cols, rows)
        new.write(dest_path)
      end
    end
  end

  puts "Done"
end

# Figure out paths
latest = GameVersion.sort(:build.desc).first

puts "Loading #{latest.version} images"

path = Rails.root.join("data", "SolForge #{latest.version}", "Payload", "solforge.app", "assets", "art@2x")

# Currency
#images = Dir[path.join("store", "gold_icon_large.png")].each do |path|
#  [path, "gold.png"]
#end
images = [
  [path.join("store", "gold_icon_large@2X.png"), "gold.png"]
]

convert_images(:currencies, images)

# Rarity
images = Dir[path.join("deck_builder", "rarity_*_icon*.png")].map do |path|
  name = File.basename(path, ".png")
  rarity_id = name.match(/_([0-9]+)_/)
  next unless rarity_id

  [path, "icon-#{rarity_id[1].to_i - 1}.png"]
end

convert_images(:rarities, images)

# Cards
images = Dir[path.join("card_art", "*.jpg")].map do |path|
  file = File.basename(path, ".jpg").gsub("@2x", "")
  [path, Card.sanitize_image(file) << ".jpg"]
end

convert_images(:cards, images)

# Borders
images = Dir[path.join("card_frames", "*.png")].map do |path|
  name = File.basename(path, ".png").gsub("@2x", "").parameterize << ".png"
  Card::INTERNAL_FACTION_MAP.each do |internal, external|
    name.gsub!(internal, external)
  end

  [path, name]
end

convert_images(:borders, images)

# Status
images = KeywordInfo.distinct(:slug).map do |keyword|
  image_path = path.join("card_misc", "#{keyword}@2x.png")
  next unless File.exists?(image_path)

  [image_path, "#{keyword}.png"]
end

convert_images(:status, images)

# Optimize
unless $changed_files.empty?
  puts "#{$changed_files.length} images changed, optimizing"

  args = $changed_files.map {|f| "'#{f}'"}.join(" ")
  `open -a ImageOptim #{args}`
end

puts
puts "Finished"