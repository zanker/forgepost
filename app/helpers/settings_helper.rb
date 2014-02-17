module SettingsHelper
  def timezone_list
    list = {}

    us_zones = {}
    ActiveSupport::TimeZone.all.each do |zone|
      category, identifier = zone.tzinfo.identifier.split("/")

      list[category] ||= []
      list[category].push([zone.to_s, zone.tzinfo.name])
    end

    list.delete("Africa")
    list.delete("Atlantic")

    list.each do |category, zones|
      added = {}
      new_zones = []

      if category == "America"
        ActiveSupport::TimeZone.us_zones.each do |zone|
          added[zone.tzinfo.name] = true
          new_zones.push([zone.to_s, zone.tzinfo.name])
        end

        new_zones.sort_by! {|z| z[0]}
        new_zones.push(["----------", ""])
      end

      zones.sort_by {|z| z[0][0]}.each do |zone|
        next if added[zone.last]
        added[zone.last] = true
        new_zones.push(zone)
      end

      list[category] = new_zones
    end

    list
  end
end