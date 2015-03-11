# This class represents a series of commemorative plaques often to commemorate an event such as a town's anniversary. 
# A Series is usually marked on the plaque itself
#
# === Attributes
# * +name+ - The name of the series (as it appears on the plaques).
# * +description+ - A description of when amd why a series was erected.
#
# === Associations
# * Plaques - plaques in this series.
class Series < ActiveRecord::Base

  validates_presence_of :name
  has_many :plaques
  default_scope { order('name ASC') }

  attr_accessor :latitude, :longitude

  include PlaquesHelper

  def find_centre
    if !geolocated?
      @mean = find_mean(self.plaques)
      self.latitude = @mean.latitude
      self.longitude = @mean.longitude
    end
  end

  def geolocated?
    return !(self.latitude == nil && self.longitude == nil || self.latitude == 51.475 && self.longitude == 0)
  end

  def uri
    "http://storystorm.herokuapp.com" + Rails.application.routes.url_helpers.series_path(self.id, :format=>:json) if id
  end

  def as_json(options={})
  	self.find_centre
  	if options.size == 0
      options = 
      {
        :only => [:name, :description],
        :methods => :uri
      }
    end

    # use a geojson format wrapper
    {
      type: 'Feature',
      geometry: 
      {
        type: 'Point',
        coordinates: [self.longitude, self.latitude]
      },
      properties: 
        super(options)
    }
  end

end
