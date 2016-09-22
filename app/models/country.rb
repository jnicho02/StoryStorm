# A top-level region definition as defined by the ISO country codes specification.
# === Attributes
# * +name+ - the country's common name (not necessarily its official one).
# * +alpha2+ - 2-letter ISO standard code. Used in URLs.
# * +description+ - commentary on how this region commemorates subjects
# * +dbpedia_uri+ - uri to link to DBPedia record
# * +areas_count+ - cached count of areas
# * +plaques_count+ - cached count of plaques
# * +created_at+
# * +updated_at+
class Country < ActiveRecord::Base

  has_many :areas
  has_many :plaques, through: :areas

  @@latitude = nil
  @@longitude = nil
  @@p_count = 0

  validates_presence_of :name, :alpha2
  validates_uniqueness_of :name, :alpha2

  include PlaquesHelper

  def find_centre
    if !geolocated?
      @mean = find_mean(self.areas)
      @@latitude = @mean.latitude
      @@longitude = @mean.longitude
    end
  end

  def geolocated?
    return !(@@latitude == nil || @@longitude == nil || @@latitude == 51.475 && @@longitude == 0)
  end

  def latitude
    @@latitude
  end

  def longitude
    @@longitude
  end

  def plaques_count
    @@p_count = areas.sum(:plaques_count) if @@p_count = 0
    @@p_count
  end

  def zoom
    6
  end

  def as_json(options={})
    options = {
      only: [:name],
      methods: [:uri, :plaques_count, :areas_count]
    } if !options || !options[:only]
    super options
  end

  def to_param
    alpha2
  end

  def uri
    "http://openplaques.org" + Rails.application.routes.url_helpers.country_path(self, format: :json) if id
  end

  def to_s
    name
  end

end
