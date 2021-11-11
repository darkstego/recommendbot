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
