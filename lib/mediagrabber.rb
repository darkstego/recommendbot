require "imdb"

#
#
#

class MediaGrabber
  MEDIA_TYPES = [:tv,:mov]
  # SEARCHABLE TYPES
  TV = :tv
  MOVIE = :mov


  def get_media_list(name,type,size = 10)
    list = case type
           when TV
             get_tv_list(name)
           when MOVIE
             get_movie_list(name)
           end
    return list.first(size)
  end

  
  private

  def imdb_url_cleanup(url)
    url.sub!("akas","www").slice!("combined")
    url
  end
  
  def get_tv_list(name)
    list = Imdb::Search.new(name).movies.select do |x|
      x.title.include?("(TV Series)") and !x.title.include?("(TV Episode)")
    end
    list.map do |x|
      x.url = imdb_url_cleanup(x.url)
      x
    end
  end

  def get_movie_list(name)
    list = Imdb::Search.new(name).movies.select do |x|
      !x.title.include?("(TV Series)") and !x.title.include?("(TV Episode)")
    end
    list.map do |x|
      x.url = imdb_url_cleanup(x.url)
      x
    end
  end
end
