require 'mediagrabber'
require 'igdb_client'

class IGDBGrabber < MediaGrabber
  def initialize(type)
    super(type)
    @client = IGDB::Client.new(@secrets[:igdb_client_id], @secrets[:igdb_client_secret])
  end

  def get_list(title, limit)
    fields = "name, summary, cover.*, url"
    results = @client.search(title, {fields: fields, limit: limit})
    results.map do |x|
      puts x
      image = x.cover ? "https:" + x.cover.url : "http://via.placeholder.com/250x250"
      image['t_thumb'] = 't_cover_big' if image['t_thumb']
      MediaItem.new(@type,x.name,x.url,image,x.summary)
    end
  end
end
