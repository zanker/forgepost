class StatsController < ApplicationController
  def online
    @stat_type = GameStat::ONLINE
    show
  end

  def total_cards
    @stat_type = GameStat::TOTAL_CARDS
    show
  end

  def total_sold
    @stat_type = GameStat::TOTAL_SOLD
    show
  end

  def total_gold
    @stat_type = GameStat::TOTAL_GOLD
    show
  end

  private
  def show
    modified = Rails.cache.read("stat-cache")
    modified = modified ? Time.at(modified.to_i) : Time.now.utc
    return unless stale?(:last_modified => modified, :etag => "stats/cache/#{@stat_type}/#{modified}")

    # Grab day/week stats
    @stats_day, @stats_week, @bands = Rails.cache.fetch("stats/cache/#{@stat_type}", :expires_in => 30.minutes) do
      threshold = 24.hours.ago.utc
      day_agg, week_agg = 10.minutes * 1000, 60.minutes * 1000

      day_points, week_points = [], []
      GameStat.where(:type => @stat_type, :created_at.gte => 7.days.ago.utc).sort(:created_at.asc).each do |stat|
        data = [stat.created_at.to_i * 1000, stat.total]

        if stat.created_at >= threshold
          if !day_points[0] or (data[0] - day_points.last[0]) >= day_agg
            day_points << data
          end
        end

        if !week_points[0] or (data[0] - week_points.last[0]) >= week_agg
          week_points << data
        end
      end


      # Include game version
      bands = []
      GameVersion.where(:created_at.gte => 7.days.ago.utc).ignore(:log).each do |version|
        bands << {
          :from => version.created_at.to_i * 1000,
          :to => (version.created_at.to_i + 1.day) * 1000,
          :color => "rgba(186, 129, 6, 0.35)",
          :label => {
            :text => t("version", :version => version.version),
            :y => -10,
            :style => {:color => "#F3C90C"}
          }
        }
      end

      [day_points.to_json, week_points.to_json, bands.to_json]
    end

    render :show
  end
end