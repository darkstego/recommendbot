require "themoviedb"
require "configatron"
require "igdb_client"
require "myanimelist_client"
require "googlebooks"
require 'config'


class MediaItem
  attr_reader :type,:title,:url,:image,:blurb,:display

  def initialize(type,title,url,image,blurb="",display=nil)
    @type = type
    @title = title
    @url = url
    @image = image
    @blurb = blurb
    @display = display
  end
end

class MediaGrabber

  SEARCH_LIMIT = 5
  MEDIA_TYPES = [:tv,:mov,:vg,:ani,:book]
  # SEARCHABLE TYPES
  TV = :tv
  MOVIE = :mov
  VG = :vg
  ANI = :ani
  BOOK = :book

  def initialize
    Tmdb::Api.key(configatron.tmdb.api_key)
    config = Tmdb::Configuration.new
	 @poster_path = config.base_url + config.poster_sizes[3]
	 @vg_client = IGDB::Client.new configatron.igdb.api_key
    @anime_client = MyanimelistClient.new(configatron.anime.uname,
                                          configatron.anime.pass)
  end

  def get_media_list(name,type)
    list = case type
           when TV
             get_tv_list(name)
           when MOVIE
             get_movie_list(name)
           when VG
             get_videogame_list(name)
           when ANI
             get_anime_list(name)
           when BOOK
             get_book_list(name)
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
    @poster_path + mov[hash_id].first["poster_path"].to_s
  end

  def get_book_list(name)
    GoogleBooks.search(name).to_a.map do |x|
       MediaItem.new(BOOK,x.title,x.info_link,
                     x.image_link(:zoom => 2),
                     x.description, x.title + " - " + x.authors)
    end
  end

  def get_anime_list(name)
    @anime_client.search_anime(name).first(5).to_a.map do |x|
      MediaItem.new(ANI,x.title,"https://myanimelist.net/anime/#{x.id}/",
                    x.image,x.synopsis)
    end
  end

  def get_videogame_list(name)
	  results = @vg_client.search_games name, {fields: "*", limit: SEARCH_LIMIT}
	  results.map do |x|
		  image = x.cover ? "https:" + x.cover.url : "http://via.placeholder.com/250x250"
		  image['t_thumb'] = 't_cover_big' if image['t_thumb']
		  MediaItem.new(VG,x.name,x.url,image,x.summary)
	  end
  end

  def get_tv_list(name)
    list = Tmdb::TV.find(name)
    list = list.first(SEARCH_LIMIT)
    list.map do |x|
      url = imdb_url_create(Tmdb::TV.external_ids(x.id)["imdb_id"])
      image = @poster_path + x.poster_path.to_s
      blurb = x.overview.to_s
      year = x.first_air_date.first 4
      title = "#{x.name} (#{year})"
      MediaItem.new(TV,title,url,image,blurb)
    end
  end

  def get_movie_list(name)
    list = Tmdb::Movie.find(name)
    list = list.first(SEARCH_LIMIT)
    list.map do |x|
      url = imdb_url_create(Tmdb::Movie.detail(x.id)["imdb_id"])
      image = @poster_path + x.poster_path.to_s
      blurb = x.overview
      year = x.release_date.first 4
      title = "#{x.title.to_s} (#{year.to_s})"
      MediaItem.new(MOVIE,title,url,image,blurb)
    end
  end

end
