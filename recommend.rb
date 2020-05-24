# coding: utf-8
# This is an advanced recommendation bot.... for recommendations
$:.unshift File.expand_path("../lib", __FILE__)
$:.unshift File.expand_path("../config", __FILE__)


require 'rubygems'
require 'bundler/setup'
require 'config'
require 'mediagrabber'
require 'tables'
require 'recommendboterror'
require 'discordrb'


bot = Discordrb::Bot.new token: configatron.token, client_id: configatron.client_id

@db = Airtable.new
@grabber = MediaGrabber.new
@announce_time = Time.now - (60*60)
@announce_backoff = 90*60

def parse_command(s)
  m = s.match(/!rc (\w+)\s+(.*)/)
  raise "Can't Parse Command" unless m
  command,text = m.captures
  command = command.downcase.to_sym
  command ||= :unknown
  return [command,text]
end

# TV "The Expanse" 5 "Great Show"
def parse_add_media(event,text)
  m = text.match(/(\w+)\s+"(.*)"\s+(\d)+\s"(.*)"/)
  raise 'Syntax incorrect Use TYPE "title" score "review"' unless m
  type,title,score,review = m.captures
  
  case(type.downcase.to_sym)
  when *MediaGrabber::MEDIA_TYPES
    type = type.downcase.to_sym
  else
    raise "Invalid Media Type"
  end
  score = score.to_i
  raise "Invalid Score" if score > 4 or score < 1

  
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
    raise "Invalid Number for selection" if ! n.between?(1,titles.size)
    e.respond titles[n-1].url
  end
end


def add_media(event,type,title,score,review)
  titles = @grabber.get_media_list(title,type)
  raise "couldn't find the title you were looking for" unless titles
  if titles.size > 1
    r = titles.each_with_index.map {|media,index|(index+1).to_s + ") #{media.display ? media.display : media.title}" }
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
  elsif titles.size == 1
    t = titles[0]
    add_to_db(event,t,score,review)
  else
    event.respond "Couldn't find any titles with that name 😾"
  end
end

# call to add info to Airtable 
def add_to_db(event,item,score,review)
  @db.add(item,event.user.id,score,review)
  airtable_url = "https://airtable.com/tblLqJXiizSuGdmlT/viwEvsUtWZBnrsetM"
  event.respond item.url.to_s
  event.respond "**#{event.user.name}** *rated this as* **#{@db.get_rating(score)}**\n#{review}\n<#{airtable_url}>"
end

bot.pm do |event|
  begin
    if Airtable::Valid_Email.match?(event.message.text)
      @db.add_user(event.user.id,event.message.text)
      event.respond "Added your email"
    end
  rescue => error
    event.respond "Couldn't add your email"
  end
end


bot.mention do |event|
  # The `pm` method is used to send a private message (also called a DM or direct message) to the user who sent the
  # initial message.
  event.user.pm('You have mentioned me!')
end



# in: "#recommendations"
reg = MediaGrabber::MEDIA_TYPES.collect {|x| x.to_s.upcase }.join("|")
bot.message(start_with: /(#{reg}) /i, in: "#recommendations") do |event|
  begin
    if @db.user_valid? event.user.id
      parse_add_media(event,event.message.text)
    else
      event.respond "I don't have your airtable email. DM me your email"
    end
  rescue => error
    event.respond error.message
  end
end

bot.voice_state_update(channel: "Dewaniya") do |event|
  if event.channel.users.size >= 2 and Time.now > @announce_time + @announce_backoff
    @announce_time = Time.now
    channel = bot.find_channel("general").first
    bot.send_message channel, "There is a party going on in Dewaniya! Hop on in"
  end
end



# This method call has to be put at the end of your script, it is what makes the bot actually connect to Discord. If you
# leave it out (try it!) the script will simply stop and the bot will not appear online.
bot.run
