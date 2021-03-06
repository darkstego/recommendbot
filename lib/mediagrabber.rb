require "themoviedb"
require "igdb_client"
require "myanimelist_client"
require "googlebooks"
require 'mediaitem'

class MediaGrabber
  SEARCH_LIMIT = 5
  # SEARCHABLE TYPES

  def initialize(secrets)
    Tmdb::Api.key(secrets[:tmdb_api_key])
    config = Tmdb::Configuration.new
    @poster_path = config.base_url + config.poster_sizes[3]
    @vg_client = IGDB::Client.new secrets[:igdb_api_key]
    @anime_client = MyanimelistClient.new(secrets[:anime_uname],
                                          secrets[:anime_pass])
  end

  def get_media_list(name,type)
    list = case type
           when MediaItem::TV
             get_tv_list(name)
           when MediaItem::MOVIE
             get_movie_list(name)
           when MediaItem::VG
             get_videogame_list(name)
           when MediaItem::ANI
             get_anime_list(name)
           when MediaItem::BOOK
             get_book_list(name)
           end
    return list
  end

  def get_image(url,type)
    case type
    when MediaItem::TV,MediaItem::MOVIE
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
    when MediaItem::TV
      prefix = "tv"
    when MediaItem::MOVIE
      prefix = "movie"
    end
    hash_id = prefix + "_results"
    @poster_path + mov[hash_id].first["poster_path"].to_s
  end

  def get_book_list(name)
    GoogleBooks.search(name).to_a.map do |x|
      MediaItem.new(MediaItem::BOOK,x.title,x.info_link,
                    x.image_link(:zoom => 2),
                    x.description, x.title + " - " + x.authors)
    end
  end

  def get_anime_list(name)
    @anime_client.search_anime(name).first(5).to_a.map do |x|
      MediaItem.new(MediaItem::ANI,x.title,"https://myanimelist.net/anime/#{x.id}/",
                    x.image,x.synopsis)
    end
  end

  def get_videogame_list(name)
    results = @vg_client.search_games name, {fields: "*", limit: SEARCH_LIMIT}
    results.map do |x|
      image = x.cover ? "https:" + x.cover.url : "http://via.placeholder.com/250x250"
      image['t_thumb'] = 't_cover_big' if image['t_thumb']
      MediaItem.new(MediaItem::VG,x.name,x.url,image,x.summary)
    end
  end

  def get_tv_list(name)
    list = Tmdb::TV.find(name)
    list = list.first(SEARCH_LIMIT)
    list.map do |x|
      url = imdb_url_create(Tmdb::TV.external_ids(x.id)["imdb_id"])
      image = @poster_path + x.poster_path.to_s
      blurb = x.overview.to_s
      year = x.first_air_date[0..3]
      title = "#{x.name} (#{year})"
      MediaItem.new(MediaItem::TV,title,url,image,blurb)
    end
  end

  def get_movie_list(name)
    list = Tmdb::Movie.find(name)
    list = list.first(SEARCH_LIMIT)
    list.map do |x|
      url = imdb_url_create(Tmdb::Movie.detail(x.id)["imdb_id"])
      image = @poster_path + x.poster_path.to_s
      blurb = x.overview
      year = x.release_date[0..3]
      title = "#{x.title.to_s} (#{year.to_s})"
      MediaItem.new(MediaItem::MOVIE,title,url,image,blurb)
    end
  end

end
