Time::DATE_FORMATS[:date] = lambda { |time| time.strftime("%B #{ActiveSupport::Inflector.ordinalize(time.day)}, %Y") }
Time::DATE_FORMATS[:time_with_zone] = lambda { |time| time.strftime("%B #{ActiveSupport::Inflector.ordinalize(time.day)}, %Y %I:%M %p (%Z)") }
Time::DATE_FORMATS[:js] = "%Y/%m/%d %H:%M:%S UTC"
Time::DATE_FORMATS[:sitemap] = "%Y-%m-%dT%H:%M:%S+00:00"