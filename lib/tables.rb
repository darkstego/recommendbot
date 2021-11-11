require 'yaml'
require 'airrecord'
require 'mediaitem'

class Media < Airrecord::Table
  self.table_name = "Media"

  has_many :review, class: 'Review', column: "Reviews"

  def self.make(hash)
    if hash.has_key?("url")
      url = hash["url"]
      shows = Media.all(filter: "{url} = \"#{url}\"")
      return shows[0] unless shows.empty?
    end
    x = new(hash)
    x.create
    return x
  end
  
end

class Review < Airrecord::Table
  self.table_name = "Reviews"

  belongs_to :tvshow, class: 'Media', column: 'Media'

end


#Email and score needs to be translated before this point
class Airtable
  Users_File = 'config/airtable_users.yml'
  RATINGS = ["Crap","Filet O Fish","Decent", "Must Experience"]
  MEDIA_NAMES = { tv: "TV Show",
                 mov: "Movie",
                 vg: "Video Game",
                 ani: "Anime",
                 book: "Book"} 
 
  def initialize()
    @users = YAML::load_file(Users_File) #Load
    secrets = Settings.secrets.to_h
    Airrecord.api_key = secrets[:airtable_api_key]
    Media.base_key = secrets[:airtable_app_key]
    Review.base_key = secrets[:airtable_app_key]
  end
  
  def add(item,user_id,score,review_text)
    email = @users[user_id]
    raise "Can't find your email for Airtable" unless email
    media = Media.make({"Title"=>item.title,
                        "url"=>item.url,
                        "Blurb"=>item.blurb,
                        "Type of Medium" => MEDIA_NAMES[item.type],
                        "Attachments"=>[{"url"=>item.image}]})
    review = Review.new( {"Review" => review_text,
                         "Rating" => get_rating(score),
                         "Media" => [media.id],
                         "Author" => {"email" => email}})
    review.create
  end


  def add_user(id,email)
    raise "Email imporperly formatted" unless Valid_Email.match(email)
    @users[id] = email.downcase
    File.open(Users_File, 'w') {|f| f.write @users.to_yaml } #Store
  end

  def get_rating(score)
    RATINGS[score-1]
  end

  def user_valid?(id)
    @users.has_key? id
  end
end


