# coding: utf-8
require 'tables'
require 'mediagrabber'
require 'recommendboterror'


class Recommendations
  VALID_EMAIL = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  def initialize(bot,secrets)
    @db = Airtable.new(secrets)
    @grabber = MediaGrabber.new(secrets)
    @bot = bot
  end

  def start()
    @bot.pm(contains: VALID_EMAIL) { |event| register_email(event)}

    # in: "#recommendations"
    reg = MediaGrabber::MEDIA_TYPES.collect {|x| x.to_s.upcase }.join("|")
    @bot.message(start_with: /(#{reg}) /i, in: "#recommendations") do |event|
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
  end

  private
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

  def add_media(event,type,title,score,review)
    titles = @grabber.get_media_list(title,type)
    raise "couldn't find the title you were looking for" unless titles
    if titles.size > 1
      r = titles.each_with_index.map do |media,index|
        (index+1).to_s + ") #{media.display ? media.display : media.title}"
      end
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

  def register_email(event)
    begin
      if VALID_EMAIL.match?(event.message.text)
        @attr = db.add_user(event.user.id,event.message.text)
        event.respond "Added your email"
      end
    rescue => error
      event.respond "Couldn't add your email"
    end
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
  
  # call to add info to Airtable 
  def add_to_db(event,item,score,review)
    @db.add(item,event.user.id,score,review)
    airtable_url = "https://airtable.com/tblLqJXiizSuGdmlT/viwEvsUtWZBnrsetM"
    event.respond item.url.to_s
    event.respond "**#{event.user.name}** *rated this as* **#{@db.get_rating(score)}**\n#{review}\n<#{airtable_url}>"
  end

end
