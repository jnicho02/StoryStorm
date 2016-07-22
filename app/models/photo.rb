# -*- encoding : utf-8 -*-
# This class represents a photograph of a Plaque.
#
# === Attributes
# * +url+ - The primary stable webpage for the photo
# * +file_url+ - A link to the actual digital photo file.
# * +thumbnail+ - A link to a thumbnail image if there is one
# * +photographer+ - The name of the photographer
# * +photographer_url+ - A link to a webpage for the photographer
# * +shot+ - types of framing technique. One of "extreme close up", "close up", "medium close up", "medium shot", "long shot", "establishing shot"
# * +of_a_plaque+ - whether this is actually a photo of a plaque (and not, for example, mistakenly labelled on Wikimedia as one)
# * +subject+ - what we think this is a photo of (used if not linked to a plaque)
# * +description+ - extra information about what this is a photo of (used if not linked to a plaque)
# * +longitude+
# * +latitude+
#
# === Associations
# * Licence - The content licence under which the photo is made available.
# * Plaque - the featured in the photo. (optional)
# * Person - the person in the photo. (optional)
require 'commoner'

class Photo < ActiveRecord::Base

  belongs_to :plaque, :counter_cache => true
  belongs_to :licence, :counter_cache => true
  belongs_to :person

  validates_presence_of :file_url
  validates_uniqueness_of :file_url, :message => "photo already exists in Open Plaques"

  attr_accessor :photo_url, :accept_cc_by_licence

  after_initialize :assign_from_photo_url
  before_validation :assign_licence_if_cc_by_accepted
  after_update :reset_plaque_photo_count
  after_save :geolocate_plaque

  scope :reverse_detail_order, -> { order('shot DESC') }
  scope :detail_order, -> { order('shot ASC') }
  scope :unassigned, -> { where(plaque_id: nil, of_a_plaque: true) }
  scope :undecided, -> { where(plaque_id: nil, of_a_plaque: nil) }
  scope :wikimedia, -> { where("file_url like 'https://commons%'") }
  scope :flickr, -> { where("url like 'http://www.flickr.com%'") }
  scope :geograph, -> { where("url like 'http://www.geograph.org.uk/%'") }
  scope :geolocated, ->  { where(["latitude IS NOT NULL"]) }

  def assign_from_photo_url
    if @photo_url
      if @photo_url =~ /http\:\/\/www\.flickr\.com\/photos\/.+\/\d+\//
        self.url = @photo_url
      else
        self.file_url = @photo_url
      end
    end
  end

  def assign_licence_if_cc_by_accepted
    if @accept_cc_by_licence && @licence_id.blank?
      self.licence = Licence.find_or_create_by_name_and_url("Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)", "http://creativecommons.org/licenses/by-sa/4.0/")
      self.photographer = self.plaque.user.name
    end
  end

  def title
    return "a photo of a " + self.plaque.to_s if self.plaque
    return "a photo of " + self.person.to_s if self.person
    title = "photo № #{id}"
    if plaque
      title = ""
      if shot_name
        title += shot_name
      else
        title += "photo"
      end
      title += " of " + plaque.title.indefinitize
    end
    return title
  end

  def attribution
    attrib = '&copy; '
    attrib += photographer.tr("./","__") if photographer
    attrib += ' on ' + source
    attrib += ' ' + licence.abbreviation if licence && licence.abbreviation != nil
    attrib += ' ' + licence.name if licence && licence.abbreviation == nil
    attrib
  end

  def shot_name
    return nil if shot == ''
    return shot[4,shot.length] if shot
  end

  def shot_order
    return shot[0,1] if shot && shot != ''
    6
  end

  def self.shots
    ["1 - extreme close up", "2 - close up", "3 - medium close up", "4 - medium shot", "5 - long shot", "6 - establishing shot"]
  end

  def flickr?
    url && url.include?("//www.flickr.com")
  end

  def wikimedia?
    url && url.include?("edia.org/")
  end

  def geograph?
    url && url.include?("//www.geograph.org.uk")
  end

  def source
    return "Flickr" if flickr?
    return "Wikimedia Commons" if wikimedia?
    return "Geograph" if geograph?
    return "the web"
  end

  def wikimedia_filename
    return url[url.index('File:')+5..-1] if wikimedia?
    return ""
  end

  def wikimedia_special
    return "https://commons.wikimedia.org/wiki/Special:FilePath/"+wikimedia_filename+"?width=640"
  end

  def flickr_photo_id
    # retrieve from url e.g. http://www.flickr.com/photos/84195101@N00/3412825200/
  end

  def thumbnail_url
    return self.thumbnail if self.thumbnail?
    if (file_url.ends_with?("_b.jpg") or file_url.ends_with?("_z.jpg") or file_url.ends_with?("_z.jpg?zz=1") or file_url.ends_with?("_m.jpg") or file_url.ends_with?("_o.jpg"))
      return file_url.gsub("b.jpg", "s.jpg").gsub("z.jpg?zz=1", "s.jpg").gsub("z.jpg", "s.jpg").gsub("m.jpg", "s.jpg").gsub("o.jpg", "s.jpg")
    end
    return "https://commons.wikimedia.org/wiki/Special:FilePath/"+wikimedia_filename+"?width=500" if wikimedia?
  end

  def wikimedia_data
    if wikimedia?
      begin
        wikimedia = Commoner.details("File:"+wikimedia_filename)
        self.url = wikimedia[:page_url]
        self.subject = wikimedia[:description]
        self.photographer = wikimedia[:author]
        self.photographer_url = wikimedia[:author_url]
        self.file_url = wikimedia_special
        licence = Licence.find_by(url: wikimedia[:licence_url])
        if (licence == nil)
          wikimedia[:licence_url] += "/" if !wikimedia[:licence_url].ends_with? '/'
          licence = Licence.find_by_url wikimedia[:licence_url]
          if (licence==nil)
            licence = Licence.new(:name => wikimedia[:licence], :url => wikimedia[:licence_url])
            licence.save
          end
        end
        self.licence = licence if licence != nil
      rescue
      end
    end
    if geograph?
      query_url = "http://api.geograph.org.uk/api/oembed?&&url=" + self.url + "&output=json"
      begin
        ch = Curl::Easy.perform(query_url) do |curl|
          curl.headers["User-Agent"] = "openplaques"
          curl.verbose = true
        end
        parsed_json = JSON.parse(ch.body_str)
        self.photographer = parsed_json['author_name']
        self.photographer_url = parsed_json['author_url']
        self.thumbnail = parsed_json['thumbnail_url']
        self.file_url = parsed_json['url']
        self.licence = Licence.find_by_url(parsed_json['license_url'])
        self.subject = parsed_json['title'][0,255]
        self.description = parsed_json['description'][0,255]
        self.latitude = parsed_json['geo']['lat']
        self.longitude = parsed_json['geo']['long']
      rescue
        puts 'Geograph Curl call failed'
      end
    end
  end

  def linked?
    !(plaque.nil?)
  end

  def geolocated?
    !(latitude.nil?)
  end

  def as_json(options={})
    options =
    {
      :only => [:file_url, :photographer, :photographer_url, :shot, :url, :longitude, :latitude],
      :include => {
        :licence => {:only => [:name], :methods => [:url]},
        :plaque => {:only => [], :methods => [:uri]}
      },
      :methods => [:title, :uri, :thumbnail_url, :shot_name, :source]
    } if !options || !options[:only]
    super options
  end

  def as_geojson(options={})
    options =
    {
      :only => [:photographer, :photographer_url, :url],
      :methods => [:thumbnail_url, :shot_name, :source]
    } if !options || !options[:only]
    {
      type: 'Feature',
      geometry:
      {
        type: 'Point',
        coordinates: [self.longitude, self.latitude]
      },
      properties: as_json(options)
    }
  end

  def as_wkt()
    return "" if (self.longitude == nil || self.latitude == nil)
    "POINT(" + self.longitude + " " + self.latitude + ")"
  end

  def uri
    "http://openplaques.org" + Rails.application.routes.url_helpers.photo_path(self, :format => :json)
  end

  def to_s
    self.title
  end

  private

    def reset_plaque_photo_count
      if plaque_id_changed?
        Plaque.reset_counters(plaque_id_was, :photos) unless plaque_id_was == nil
        Plaque.reset_counters(plaque.id, :photos) unless plaque == nil
      end
    end

    def geolocate_plaque
      if plaque && self.geolocated? && (!plaque.geolocated? || (plaque.geolocated? && !plaque.is_accurate_geolocation))
        plaque.longitude = self.longitude
        plaque.latitude = self.latitude
        plaque.is_accurate_geolocation = true
        plaque.save
      end
      return true
    end
end
