require 'airrecord'
require 'configatron'
require 'yaml'
require_relative '../config/config.rb'
require_relative 'mediagrabber.rb'

Airrecord.api_key = configatron.airtable_api_key


class TVShow < Airrecord::Table
  self.base_key = configatron.airtable_app_key
  self.table_name = "TV Shows"

  has_many :review, class: 'Review', column: "review"

  def self.make(hash)
    if hash.has_key?("url")
      url = hash["url"]
      shows = TVShow.all(filter: "{url} = \"#{url}\"")
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

  belongs_to :tvshow, class: 'TVShow', column: 'TV Shows'

end


#Email and score needs to be translated before this point
class Airtable
  Users_File = 'config/airtable_users.yml'
  Valid_Email = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  #SCORES = ["Meh","OK","Great", "Must See"]
  SCORES = {MediaGrabber::TV => ["Crap","Filet O Fish","Decent","Must Watch"],
            MediaGrabber::MOVIE => ["Crap","Filet O Fish","Decent Flick","Must Watch"],
            MediaGrabber::VG => ["Crap","Fun Time-Waster", "Decent", "Must Play"]}
    
  def initialize()
    @users = YAML::load_file(Users_File) #Load
    
  end
  
  def add(item,user_id,score,review)
    email = @users[user_id]
    raise "Can't find your email for Airtable" unless email
    show = TVShow.make({"title"=>item.title,
                        "url"=>item.url,
                        "blurb"=>item.blurb,
                       "attachment"=>[{"url"=>item.image_block.call}]})
    review = Review.new( "Review" => review,
                         "Score" => get_rating(score),
                         "TV Shows" => show,
                         "author" => {"email" => email})
    review.create
  end


  def add_user(id,email)
    raise "Email imporperly formatted" unless Valid_Email.match(email)
    @users[id] = email
    File.open(Users_File, 'w') {|f| f.write @users.to_yaml } #Store
  end

  def get_rating(score)
    SCORES[score-1]
  end
end


