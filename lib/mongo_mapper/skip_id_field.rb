module MongoMapper
  module SkipIdField
    extend ActiveSupport::Concern

    included do
      self.keys.delete("_id")
      self.class_eval <<-RUBY
          def _id; end
        def _id=(id); end
      RUBY
    end
  end
end