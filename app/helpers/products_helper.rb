module ProductsHelper
  def format_price(price)
    if price.gold?
      html = "#{number_with_delimiter(price.cost)} #{content_tag(:span, t("gold_long"), :class => "gold-type")}"
    end

    content_tag(:div, html.html_safe, :class => "currency")
  end
end