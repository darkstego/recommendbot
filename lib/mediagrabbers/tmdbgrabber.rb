require 'mediagrabber'
require 'themoviedb'

class TMDBGrabber < MediaGrabber
  BASE_URL = "https://www.themoviedb.org/"

  def initialize(type)
    super(type)
    Tmdb::Api.key(@secrets[:tmdb_api_key])
    config = Tmdb::Configuration.new
    @poster_path = config.base_url + config.poster_sizes[3]
  end

  def get_list(title,limit)
    case @type
    when :mov
      get_movie_list(title, limit)
    when :tv
      get_tv_list(title, limit)
    end
  end

  private
  def get_tv_list(name, limit)
    list = Tmdb::TV.find(name)
    list = list.first(limit)
    list.map do |x|
      url = BASE_URL + "tv/" + x.id.to_s
      image = @poster_path + x.poster_path.to_s
      blurb = x.overview.to_s
      year = x.first_air_date[0..3]
      title = "#{x.name} (#{year})"
      MediaItem.new(@type,title,url,image,blurb)
    end
  end

  def get_movie_list(name, limit)
    list = Tmdb::Movie.find(name)
    list = list.first(limit)
    list.map do |x|
      url = BASE_URL + "movie/" + x.id.to_s
      image = @poster_path + x.poster_path.to_s
      blurb = x.overview
      year = x.release_date[0..3]
      title = "#{x.title.to_s} (#{year.to_s})"
      MediaItem.new(@type,title,url,image,blurb)
    end
  end
end
