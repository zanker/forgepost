module ApplicationHelper
  def image_url(source)
    image_path(source)
  end

  def render_block(partial, &block)
    body = capture_haml(&block)
    render :partial => partial, :locals => {:body => body}
  end

  def tooltip_mark(text)
    link_to("[?]", "#", :class => "tt alt", :title => text)
  end

  def sort_header(text, key)
    sort_mode = (key == params[:sort_by] ? params[:sort_mode] == "asc" ? "desc" : "asc" : "desc")

    html = ""
    html << link_to(text, url_for(:sort_by => key, :sort_mode => sort_mode))

    if params[:sort_by] == key
      if params[:sort_mode] == "asc"
        html << content_tag(:div, "", :class => "caret-up")
      else
        html << content_tag(:div, "", :class => "caret-down")
      end
    end

    html
  end

  def active_param_class(key, value)
    ( params[key] == value.to_s ) ? :active : nil
  end

  def active_class(controller, action=nil)
    if controller == params[:controller]
      if !action or action == params[:action]
        return :active
      end
    end

    nil
  end

  def round_number(number, place)
    (number / place.to_f).round * place
  end

  def build_pagination(total, per_page)
    current_page = params[:page].to_i
    total_pages = (total / per_page.to_f).ceil
    return if total_pages <= 1

    html = ""
    if current_page > 1
      html << content_tag(:li, link_to("&laquo;".html_safe, url_for(:page => 1), :title => t("first")))
      html << content_tag(:li, link_to("&lsaquo;".html_safe, url_for(:page => current_page - 1), :title => t("previous")))
    end

    min, max = current_page - 3, current_page + 3
    min = 1 if min < 1
    max = total_pages if max > total_pages

    (min..max).each do |i|
      html << content_tag(:li, link_to("#{i}", url_for(:page => i)), :class => i == current_page ? :active : nil)
    end

    if current_page < total_pages
      html << content_tag(:li, link_to("&rsaquo;".html_safe, url_for(:page => current_page + 1), :title => t("next")))
      html << content_tag(:li, link_to("&raquo;".html_safe, url_for(:page => total_pages), :title => t("last")))
    end

    content_tag(:div, content_tag(:ul, html.html_safe), :class => :pagination)
  end

  def linkify_text(text, *args)
    text.scan(/(\{(.+?)\})/).each do |match|
      link = args.shift
      if link.is_a?(String)
        text = text.gsub(match.first, link_to(match.last, link)).html_safe
      elsif link.first == :email
        text = text.gsub(match.first, mail_to(link.last, match.last)).html_safe
      elsif link.first == :blank
        text = text.gsub(match.first, link_to(match.last, link.last, :target => "_blank")).html_safe
      end
    end

    text
  end

  def page_description_tags
    if params[:controller] == "sessions" or response.code == "404" or response.code == "500"
      return
    end

    text = ""
    if request.path == "/"
      text = t("descriptions.home")
    elsif params[:controller] == "faq"
      text = t("descriptions.faq")
    elsif params[:controller] == "store"
      if @account
        text = t("descriptions.store", :name => @account.name)
      end
    elsif params[:controller] == "deckbuilders"
      text = t("descriptions.deckbuilder")

    elsif params[:controller] == "news"
      if @post
        text = "#{(@post.short_body? ? @post.short_body : @post.body)[0, 150]}..."
      end

    elsif params[:controller] == "tooltips"
      text = t("descriptions.tooltips")

    elsif params[:controller] == "stats"
      text = t("descriptions.stat_#{params[:action]}")

    elsif params[:controller] == "cards"
      if @card and ( params[:action] == "show" || params[:action] == "show_alt" || params[:action] == "show_old" )
        if !@game_version
          text = t("descriptions.card_show", :name => @card.name, :faction => t("factions.#{@card.faction}"))
        else
          text = t("descriptions.card_show_version", :name => @card.name, :faction => t("factions.#{@card.faction}"), :version => @game_version)
        end

      elsif @card
        text = t("descriptions.card_#{params[:action]}", :name => @card.name)

      elsif params[:action] == "index"
        factions = t("all").downcase
        unless @filters[:factions].length == Card::FACTION_MAP.length
          factions << " " << @filters[:factions].map {|k, v| t("factions.#{k}")}.join(", ")
          factions.gsub!(/,(.+)$/, " " + t("and") + ' \1')
        end

        text = t("descriptions.card_search", :factions => factions)

        if @filters[:set]
          text = t("descriptions.card_search_set", :factions => factions, :set => t("card_sets.#{@filters[:set].tr(".", "_")}"))
        else
          text = t("descriptions.card_search", :factions => factions)
        end
      end

    elsif params[:controller] == "products"
      text = t("descriptions.card_specials")
    end

    return if text.blank?
    tag(:meta, :name => :description, :content => text) << tag(:meta, :property => "og:description", :content => text)
  end

  def title_tags
    title = main_page_title
    content_tag(:title, title) << tag(:meta, :property => "og:title", :content => title)
  end

  def main_page_title
    if response.code == "404"
      title = t("titles.404")

    elsif response.code == "500"
      title = t("titles.500")

    elsif params[:controller] == "privacy_policy"

    elsif params[:controller] == "sessions"
      title = t("titles.login")

    elsif params[:controller] == "deckbuilders"
      title = t("titles.deckbuilder")

    elsif params[:controller] == "users"
      title = t("titles.register")

    elsif params[:controller] == "tooltips"
      title = t("titles.tooltips")

    elsif params[:controller] == "faq"
      title = t("titles.faq")

    elsif params[:controller] == "game_patches"
      title = params[:version] ? t("titles.game_patch", version: params[:version].tr("-", ".")) : t("titles.game_patches")

    elsif params[:controller] == "references"
      if params[:action] == "faction"
        title = t("titles.references_faction", :faction => t("factions.#{Card::FACTION_MAP[params[:faction]]}"))
      else
        title = t("titles.#{params[:controller]}_#{params[:action]}")
      end

    elsif params[:controller] == "news"
      if @post
        title = @post.title
      elsif params[:page] != "1"
        title = t("titles.news_page", :page => params[:page])
      else
        title = t("titles.news")
      end

    elsif params[:controller] == "cards"
      if @card and ( params[:action] == "show" || params[:action] == "show_alt" || params[:action] == "show_old" )
        if params[:version].blank?
          title = "#{@card.name} (#{t("titles.card_show#{@alt ? "_alt" : ""}", :faction => t("factions.#{@card.faction}"))})"
        else
          title = "#{@card.name} (#{t("titles.card_show_version", :version => params[:version].gsub("-", "."), :faction => t("factions.#{@card.faction}"))})"
        end

      elsif @card
        title = "#{@card.name} (#{t("titles.card_#{params[:action]}")})"
      elsif params[:action] == "index"
        title = ""
        unless @filters[:factions].length == Card::FACTION_MAP.length
          title << @filters[:factions].map {|k, v| t("factions.#{k}")}.join(", ")
          title.gsub!(/,(.+)$/, " " + t("and") + ' \1')
        end

        if @filters[:set]
          title << " #{t("set")} #{t("card_sets.#{@filters[:set].tr(".", "_")}")} - "
        end

        title << " " << t("titles.card_search")
      end

    elsif params[:controller] == "usercp/settings"
      title = t("titles.account_management")

    elsif params[:controller] == "home"
      if params[:action] == "privacy_policy"
        title = t("titles.privacy_policy")
      elsif params[:action] == "terms_conditions"
        title = t("titles.terms_conditions")
      end

    elsif params[:controller] == "products"
      title = t("titles.card_specials")
    end

    title.strip! if title
    "#{title || t("titles.home")} - ForgePost"
  end

  def relative_seconds(seconds, mode=nil)
    text = case seconds
      when 0..59 then t("seconds#{(mode == :short ? "_short" : "")}", :count => seconds)
      when 60..3599 then t("minutes#{(mode == :short ? "_short" : "")}", :count => seconds / 60)
      when 3600..86399 then t("hours#{(mode == :short ? "_short" : "")}", :count => seconds / 3600)
      when 86400..604800 then t("days", :count => seconds / 86400)
    end

    if mode == :old
      "#{text} #{t("old")}"
    else
      text
    end
  end

  def relative_time(time, mode=nil)
    seconds = (Time.now.utc - time).to_i
    text = case seconds
      when 0..59 then t("seconds#{(mode == :short || mode == :short_ago) && "_short" || ""}", :count => seconds)
      when 60..3599 then t("minutes#{(mode == :short || mode == :short_ago) && "_short" || ""}", :count => seconds / 60)
      when 3600..86399 then t("hours#{(mode == :short || mode == :short_ago) && "_short" || ""}", :count => seconds / 3600)
      when 86400..604800 then t("days", :count => seconds / 86400)
    end

    return time.to_date.to_s(:long_ordinal) unless text

    if mode == :ago or mode == :short_ago
      "#{text} #{t("ago")}"
    elsif mode == :old
      "#{text} #{t("old")}"
    else
      text
    end
  end
end
