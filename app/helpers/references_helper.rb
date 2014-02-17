module ReferencesHelper
  def parse_keyword_info(text)
    text.gsub("<value>", content_tag(:span, "#", :class => :gold))
  end
end