require 'airrecord'
require 'configatron'
require 'yaml'
require_relative '../config/config.rb'
require_relative 'mediagrabber.rb'

Airrecord.api_key = configatron.airtable_api_key


class Media < Airrecord::Table
  self.base_key = configatron.airtable_app_key
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
  self.base_key = configatron.airtable_app_key
  self.table_name = "Reviews"

  belongs_to :tvshow, class: 'Media', column: 'Media'

end


#Email and score needs to be translated before this point
class Airtable
  Users_File = 'config/airtable_users.yml'
  Valid_Email = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  RATINGS = ["Crap","Filet O Fish","Decent", "Must Experience"]
  MEDIA_NAMES = {MediaGrabber::TV => "TV Show",
                 MediaGrabber::MOVIE => "Movie",
                 MediaGrabber::VG => "Video Game"} 
 
  def initialize()
    @users = YAML::load_file(Users_File) #Load
    
  end
  
  def add(item,user_id,score,review)
    email = @users[user_id]
    raise "Can't find your email for Airtable" unless email
    media = Media.make({"Title"=>item.title,
                        "url"=>item.url,
                        "Blurb"=>item.blurb,
                        "Type of Medium" => MEDIA_NAMES[item.type],
                       "Attachments"=>[{"url"=>item.image}]})
    review = Review.new( "Review" => review,
                         "Rating" => get_rating(score),
                         "Media" => media,
                         "Author" => {"email" => email})
    review.create
  end


  def add_user(id,email)
    raise "Email imporperly formatted" unless Valid_Email.match(email)
    @users[id] = email
    File.open(Users_File, 'w') {|f| f.write @users.to_yaml } #Store
  end

  def get_rating(score)
    RATINGS[score-1]
  end
end


