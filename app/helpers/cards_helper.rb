module CardsHelper
  def parse_keyword(card, text)
    return text unless @tooltip_data["keywords"][text]

    keyword = @tooltip_data["keywords"][text]

    content_tag(:div, "#{image_tag("status/tiny/#{keyword[0]}.png", :height => 19, :width => 20)} #{link_to(text, cards_index_search_url(:keywords => keyword[0], :level => card.level), :class => :tt, :title => keyword[1])}".html_safe, :class => :keyword)
  end

  def parse_text(card, text)
    @tooltip_data["help"].each do |type, desc|
      if text =~ /^#{type}/
        text = content_tag(:div, text.gsub(/^#{type}/, link_to(type, cards_index_search_url(:keywords => type.parameterize, :level => card.level), :class => :tt, :title => desc)).html_safe, :class => :misc)
      end
    end

    text
  end

  def parse_ability(card, text)
    text = text.gsub(/<this>/i, card.name)
    text = text.gsub(/<ignore>/i, "")

    # Add Free + Activate
    @tooltip_data["help"].each do |type, desc|
      if text =~ /^#{type}/
        text = text.gsub(/^#{type}/, link_to(type, cards_index_search_url(:keywords => type.parameterize, :level => card.level), :class => :tt, :title => desc))
      end
    end

    # Parse any conditional keywords
    type_used = {}
    @tooltip_data["keywords"].each do |type, data|
      next if type_used[data[0]]

      if text =~ /#{type}/
        type_used[data[0]] = true
        text = text.gsub(/#{type}/, "#{image_tag("status/tiny/#{data[0]}.png", :height => 15, :width => 16)} #{link_to(type, cards_index_search_url(:keywords => data[0], :level => card.level), :class => :tt, :title => data[1])}")
      end
    end

    # Parse anything else like +attack or +health
    text.scan(/([\-\+]?[0-9]+ (attack|health))/i).each do |match, type|
      text.gsub!(match, content_tag(:span, match, :class => type.downcase))
    end

    text
  end

  def card_changed?(field, index)
    live_card = @next_card_levels[index]
    old_card = @card_levels[index]

    live_card[field] != old_card[field]
  end

  def render_card_data(field, index, &block)
    live_card = @next_card_levels && @next_card_levels[index]
    old_card = @card_levels[index]

    if !live_card || live_card[field] == old_card[field]
      if block_given?
        capture_haml(old_card, &block)
      else
        old_card[field]
      end
    elsif block_given?
      show_diff_html(capture_haml(old_card, &block), capture_haml(live_card, &block))
    else
      show_diff_html(old_card[field], live_card[field])
    end
  end

  def show_diff_html(old, live)
    if @next_version_id == @active_version_id
      next_version = t("live")
    else
      next_version = t("version", version: GameVersion.id_to_version(@next_version_id))
    end

    old = content_tag(:div, "#{content_tag(:div, "#{t("version", :version => @game_version)}:", :class => :version)} #{old}".html_safe, :class => :old)
    new = content_tag(:div, "#{content_tag(:div, "#{next_version}:", :class => :version)} #{live}".html_safe, :class => :new)
    content_tag(:div, old << new, :class => :diff)
  end
end