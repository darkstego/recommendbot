require 'mediaitem'

class MediaGrabber
  def initialize(type)
    @secrets = Settings.secrets.to_h
    @type = type
  end
  
  def get_list(title,limit)
  end
end
