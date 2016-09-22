# This class represents content licences, such as those produced by the Creative Commons
# organisation.
# === Attributes
# * +name+ - the full name
# * +abbreviation+ - short name, e.g. CC BY-NC-SA 2.0
# * +url+ - a permanent URL at which the licence.
# * +allows_commercial_reuse+ - commercial usage rights
# * +photos_count+ - cached count of photos
#
# === Associations
# * Photos - photographed which are published under this licence
class Licence < ActiveRecord::Base

  validates_presence_of :name, :url
  validates_uniqueness_of :url

  has_many :photos

  def self.find_by_flickr_licence_id(flickr_licence_id)
    case flickr_licence_id
    when "0"
      return Licence.find_by_url("http://en.wikipedia.org/wiki/All_rights_reserved/")
    when "1"
      return Licence.find_by_url("http://creativecommons.org/licenses/by-nc-sa/2.0/")
    when "2"
      return Licence.find_by_url("http://creativecommons.org/licenses/by-nc/2.0/")
    when "3"
      return Licence.find_by_url("http://creativecommons.org/licenses/by-nc-nd/2.0/")
    when "4"
      return Licence.find_by_url("http://creativecommons.org/licenses/by/2.0/")
    when "5"
      return Licence.find_by_url("http://creativecommons.org/licenses/by-sa/2.0/")
    when "6"
      return Licence.find_by_url("http://creativecommons.org/licenses/by-nd/2.0/")
    when "7"
      return Licence.find_by_url("http://www.flickr.com/commons/usage/")
    when "8"
      return Licence.find_by_url("http://www.usa.gov/copyright.shtml")
    when "9"
      return Licence.find_by_url("http://creativecommons.org/publicdomain/zero/1.0/")
    when "10"
      return Licence.find_by_url("http://creativecommons.org/publicdomain/mark/1.0/")
    else
      puts "Couldn't find license"
      return nil
    end
  end

  def creative_commons?
    url =~ /creativecommons.org\/licenses/i
  end

  def to_s
    name
  end

  def as_json(options={})
    options = {
      only: [:name, :abbreviation, :url, :allows_commercial_reuse, :photos_count]
    } if !options || !options[:only]
    super options
  end
end
