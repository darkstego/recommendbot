require 'igdbgrabber'
require 'tmdbgrabber'

class ListFactory
  MEDIA_TYPES = {mov: 'Movie',
                 tv: 'TV Series',
                 vg: 'Video Game',
                 }

  def self.get_media_list(type, title, limit)
    get_media_grabber(type).get_list(title, limit)
  end

  private
  def self.get_media_grabber(type)
    raise "Media Type [#{type}] is not valid" unless MEDIA_TYPES.has_key?(type)
    case type
    when :mov
      @mov_grabber ||= TMDBGrabber.new(type)
    when :tv
      @tv_grabber ||= TMDBGrabber.new(type)
    when :vg
      @vg_grabber ||= IGDBGrabber.new(type)
    end
  end
end
