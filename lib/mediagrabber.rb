require "themoviedb"
require "configatron"
require "giant_bomb_api"
require_relative '../config/config.rb'


class MediaItem
  attr_reader :type,:title,:url,:image,:blurb

  def initialize(type,title,url,image,blurb="")
    @type = type
    @title = title
    @url = url
    @image = image
    @blurb = blurb
  end
end

class MediaGrabber

  SEARCH_LIMIT = 5
  MEDIA_TYPES = [:tv,:mov,:vg]
  # SEARCHABLE TYPES
  TV = :tv
  MOVIE = :mov
  VG = :vg

  def initialize
    Tmdb::Api.key(configatron.tmdb.api_key)
    config = Tmdb::Configuration.new
    @poster_path = config.base_url + config.poster_sizes[3]
    GiantBombApi.configure do |config|
      config.api_key = configatron.giantbomb.api_key
    end
  end

  def get_media_list(name,type)
    list = case type
           when TV
             get_tv_list(name)
           when MOVIE
             get_movie_list(name)
           when VG
             get_videogame_list(name)
           end
    return list
  end

  def get_image(url,type)
    case type
    when TV,MOVIE
      get_tmdb_poster(imdb_id(url),type)
    end
  end

  
  private

  def imdb_url_create(id)
    "http://www.imdb.com/title/#{id.to_s}/"
  end
  
  def imdb_url_cleanup(url)
    url.sub!("akas","www").slice!("combined")
    url
  end

  def imdb_id(url)
    match = /(tt\d+)/.match(url)
    if match
      return match.captures[0]
    else
      raise "Couldn't find imdb id from URL given"
    end
  end

  def get_tmdb_poster(id,type)
    mov = Tmdb::Find.imdb_id(id)
    raise "Couldn't find a tmbd entry with that imdb id" unless mov
    case type
    when TV
      prefix = "tv"
    when MOVIE
      prefix = "movie"
    end
    hash_id = prefix + "_results"
    @poster_path + mov[hash_id].first["poster_path"]
  end


  def get_videogame_list(name)
    search = GiantBombApi::Request::Search.new(name,resources: [GiantBombApi::Resource::Game], limit: SEARCH_LIMIT)
    results = GiantBombApi.client.send_request(search)
    list = results.results
    list.map do |x|
      MediaItem.new(VG,x.name,x.site_detail_url,x.image.medium_url,x.deck)
    end

  end
  
  def get_tv_list(name)
    list = Tmdb::TV.find(name)
    list = list.first(SEARCH_LIMIT)
    list.map do |x|
      url = imdb_url_create(Tmdb::TV.external_ids(x.id)["imdb_id"])
      image = @poster_path + x.poster_path
      blurb = x.overview
      year = x.first_air_date.first 4
      title = "#{x.name} (#{year})"
      MediaItem.new(TV,title,url,image,blurb)
    end
  end

  def get_movie_list(name)
    list = Tmdb::Movie.find(name)
    list = list.first(SEARCH_LIMIT)
    list.map do |x|
      url = imdb_url_create(x.imdb_id)
      image = @poster_path + x.poster_path
      blurb = x.overview
      year = x.release_date.first 4
      title = "#{x.title} (#{year})"
      MediaItem.new(MOVIE,title,url,image,blurb)
    end
  end

end
