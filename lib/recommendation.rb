# coding: utf-8
require 'tables'
require 'mediagrabber'
require 'mediaitem'

class Recommendations
  VALID_EMAIL = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  def self.register_commands(bot,server_id)
    bot.register_application_command(:recommend, 'Recommendation commands',
                                     server_id: server_id) do |cmd|
      cmd.subcommand(:review, 'Post a Review') do |sub|
        sub.string('type', 'Media Type', required: true,
                   choices: {'Movie' => 'mov',
                             'TV Series' => 'tv',
                             'Video Game' => 'vg',
                            'Book' => 'book'})
        sub.string('title', 'Title', required: true)
        sub.integer('score', 'Score', required: true,
                    choices: {'Must Experience': 4,
                              'Decent': 3,
                              'Filet-O-Fish': 2,
                              'Crap': 1})
        sub.string('review', 'Review', required: true)
      end

      cmd.subcommand(:register, 'Register Airtable Email') do |sub|
        sub.string('email', 'Your Email Address', required: true)
      end
    end
  end

  
  def self.unregister_commands(bot,server_id)
    ## Requires command_id and no clue how to obtain that
    # bot.delete_application_command(:recommend,
    #                                server_id: server_id) 
  end
  
  def initialize(bot,secrets)
    @db = Airtable.new(secrets)
    @grabber = MediaGrabber.new(secrets)
    @bot = bot
    
    @bot.application_command(:recommend).subcommand(:review) do |event|
      begin
        if @db.user_valid? event.user.id
          parse_add_media(event)
        else
          event.respond(content: "I don't have your airtable email. Please Register your email",
                        ephemeral: true)
        end
      rescue => error
        event.channel.send_message error.message
      end
    end
    
    @bot.application_command(:recommend).subcommand(:register) do |event|
      register_email(event)
    end
  end

  private
  # TV "The Expanse" 5 "Great Show"
  def parse_add_media(event)
    case(event.options['type'].downcase.to_sym)
    when *MediaItem::MEDIA_TYPES
      type = event.options['type'].downcase.to_sym
    else
      raise "Invalid Media Type"
    end
    score = event.options['score'].to_i
    raise "Invalid Score" if score > 4 or score < 1
    
    add_media(event,type,event.options['title'],score,event.options['review'])
  end

  def add_media(event,type,title,score,review)
    titles = @grabber.get_media_list(title,type)
    raise "couldn't find the title you were looking for" unless titles
    if titles.size > 1
      r = titles.each_with_index.map do |media,index|
        (index+1).to_s + ") #{media.display ? media.display : media.title}"
      end
      response = "Pick Number of Title you are looking for, or 0 to cancel\n"
      response += r.join("\n")
      event.respond(content: response, ephemeral: true)
      event.channel.await(author: event.user,contains: /^(\d+)/) do |e|
        n = e.message.text.match(/(\d+)/).captures.first.to_i
        if n.zero?
          event.send_message(content: "Cancelled", ephemeral: true)
        elsif !n.between?(1,titles.size)
          event.send_message(content: "Invalid Number for selection",
                        ephemeral: true)
        else
          t = titles[n-1]
          add_to_db(event,t,score,review)
        end
        #TODO: check permissions before deleting
        e.message.delete 
      end
    elsif titles.size == 1
      t = titles[0]
      add_to_db(event,t,score,review)
      event.respond(content: "Done", ephemeral: true)
    else
      event.respond(content: "Couldn't find any titles with that name 😾",
                    ephemeral: true)
    end
  end

  def register_email(event)
    begin
      if VALID_EMAIL.match?(event.options['email'])
        @db.add_user(event.user.id,event.options['email'])
        event.respond(content: "Email registered")
      else
        event.respond(content: "#{event.options['email']} not a valid email",
                      ephemeral: true)
      end
    rescue => error
      event.channel.send_message(content:"Couldn't add your email #{event.options[:email]}",
                    ephemeral: true)
    end
  end
  
  # call to add info to Airtable 
  def add_to_db(event,item,score,review)
    @db.add(item,event.user.id,score,review)
    channel = event.server.text_channels.find {|c| c.name == 'recommendations'}
    channel ||= event.channel
    channel.send_message item.url.to_s
    channel.send_message "**#{event.user.name}** *rated this as* **#{@db.get_rating(score)}**\n#{review}"
    # event.delete_response
  end
  
end
