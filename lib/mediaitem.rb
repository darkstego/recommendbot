class MediaItem
  attr_reader :type,:title,:url,:image,:blurb,:display
  TV = :tv
  MOVIE = :mov
  VG = :vg
  ANI = :ani
  BOOK = :book
  MEDIA_TYPES = [TV,MOVIE,VG,ANI,BOOK]

  def initialize(type,title,url,image,blurb="",display=nil)
    @type = type
    @title = title
    @url = url
    @image = image
    @blurb = blurb
    @display = display
  end
end
