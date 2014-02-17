class GameVersion
  include MongoMapper::Document

  key :version, String
  key :build, Integer
  key :created_at, Time

  def self.next_version_id(id)
    id = Rails.cache.fetch("next-version-id-#{id}", :expires_in => 1.hour) do
      version = self.where(:_id.gt => id).sort(:created_at.asc).limit(1).only(:_id).first
      version ? version._id.to_s : ""
    end

    id == "" ? nil : BSON::ObjectId(id)
  end

  def self.active_version_id
    id = Rails.cache.fetch("active-version-id", :expires_in => 1.hour) do
      self.sort(:created_at.desc).limit(1).only(:_id).first._id.to_s
    end

    BSON::ObjectId(id)
  end

  def self.active_version
    Rails.cache.fetch("active-version", :expires_in => 1.hour) do
      self.sort(:created_at.desc).limit(1).only(:version).first.version
    end
  end

  def self.version_to_id(version)
    id = Rails.cache.fetch("version-id-#{version}", :expires_in => 24.hours) do
      version = self.where(:version => version).only(:_id).first

      version ? version._id.to_s : ""
    end

    id == "" ? nil : BSON::ObjectId(id)
  end

  def self.id_to_version(id)
    Rails.cache.fetch("version-id-#{id}", :expires_in => 1.week) do
      version = self.where(:_id => id.to_s).only(:version).first
      version ? version.version : ""
    end
  end
end