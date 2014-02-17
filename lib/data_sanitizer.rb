module DataSanitizer
  # Their data can be wonky, try and fix it
  def sanitize_data(data)
    if data.is_a?(Hash)
      data.each do |key, value|
        if value.is_a?(Array) or value.is_a?(Hash)
          data[key] = sanitize_data(value)
        elsif value.is_a?(String)
          value.strip!
        end
      end
    else
      data.each do |value|
        if value.is_a?(Array) or value.is_a?(Hash)
          sanitize_data(value)
        elsif value.is_a?(String)
          value.strip!
        end
      end
    end

    data
  end
end