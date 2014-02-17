class Post
  include MongoMapper::Document

  key :title, String
  key :slug, String

  key :short_body, String
  key :body, String

  timestamps!

  def self.last_post
    Rails.cache.fetch("news", :expires_in => 30.minutes) do
      post = Post.only(:created_at).sort(:created_at.desc).first
      post ? post.created_at.to_i : 0
    end
  end
end