# This is an advanced recommendation bot.... for recommendations

require 'discordrb'
require 'configatron'
require_relative 'config/config.rb'
require_relative 'lib/mediagrabber.rb'
require_relative 'lib/tables.rb'
require_relative 'lib/recommendboterror.rb'


bot = Discordrb::Bot.new token: configatron.token, client_id: configatron.client_id

@db = Airtable.new
@grabber = MediaGrabber.new


def parse_command(s)
  
  m = s.match(/!rc (\w+)\s+(.*)/) 
  raise RecommendBotError.new("Can't Parse Command",:command_parse_fail) unless m
  command,text = m.captures
  command = command.downcase.to_sym
  command ||= :unknown
  return [command,text]
end

# TV "The Expanse" 5 "Great Show"
def parse_add_media(event,text)
  m = text.match(/(\w+)\s+"(.*)"\s+(\d)+\s"(.*)"/)
  raise RecommendBotError('Syntax incorrect Use TYPE "title" score "review" ',:add_match_fail) unless m
  type,title,score,review = m.captures
  
  case(type.downcase.to_sym)
  when *MediaGrabber::MEDIA_TYPES
    type = type.downcase.to_sym
  else
    raise RecommendBotError.new("Invalid Media Type",:media_type_fail)
  end
  score = score.to_i
  raise RecommendBotError.new("Invalid Score",:media_score_fail) if score > 4 or score < 1

  
  add_media(event,type,title,score.to_i,review)
  
end


def fetch_title_url(event,title,type)
  titles = @grabber.get_media_list(title,type)
  return titles[0] if titles.size == 1
  r = titles.each_with_index.map {|media,index|(index+1).to_s + ") #{media.title}" }

  event.respond("Pick Number of Title you are looking for")
  event.respond(r.join("\n"))
  event.channel.await(author: event.author,contains: /^(\d+)/) do |e|
    n = e.message.text.match(/(\d+)/).captures.first.to_i 
    raise RecommendBotError.new("Invalid Number for selection",:media_select_fail) if ! n.between?(1,titles.size)
    e.respond titles[n-1].url
  end
  
end
  

def add_media(event,type,title,score,review)
  titles = @grabber.get_media_list(title,type)
  raise "couldn't find the title you were looking for" unless titles
  if titles.size > 1
    r = titles.each_with_index.map {|media,index|(index+1).to_s + ") #{media.title}" }
    event.respond("Pick Number of Title you are looking for, or 0 to cancel")
    event.respond(r.join("\n"))
    event.channel.await(author: event.author,contains: /^(\d+)/) do |e|
      n = e.message.text.match(/(\d+)/).captures.first.to_i
      if n.zero?
        e.respond "Cancelled"
      elsif !n.between?(1,titles.size)
        e.respond "Invalid Number for selection"
      else
        t = titles[n-1]
        add_to_db(e,t,score,review)
      end
    end
  else
    t = titles[0]
    add_to_db(event,t,score,review)
  end
end

# call to add info to Airtable 
def add_to_db(event,item,score,review)
  @db.add(item,event.user.id,score,review)
  airtable_url = "https://airtable.com/tblLqJXiizSuGdmlT/viwEvsUtWZBnrsetM"
  event.respond item.url
  event.respond "**#{event.user.name}** rated this as **#{@db.get_rating(score)}**\n*#{review}*\n<#{airtable_url}>"
end

bot.pm do |event|
  if Airtable::Valid_Email.match?(event.message.text)
    @db.add_user(event.user.id,event.message.text)
  end
end


bot.mention do |event|
  # The `pm` method is used to send a private message (also called a DM or direct message) to the user who sent the
  # initial message.
  event.user.pm('You have mentioned me!')
end



reg = MediaGrabber::MEDIA_TYPES.collect {|x| x.to_s.upcase }.join("|")
bot.message(start_with: /#{reg}/) do |event|
  begin
    parse_add_media(event,event.message.text)
  rescue => error
    event.respond error.message
  end
end



# This method call has to be put at the end of your script, it is what makes the bot actually connect to Discord. If you
# leave it out (try it!) the script will simply stop and the bot will not appear online.
bot.run
