# coding: utf-8
require 'tables'
require 'listfactory'

class Recommendations
  SEARCH_LIMIT = 5

  def self.register_commands(bot,server_id)
    media_choices = Hash[ListFactory::MEDIA_TYPES.map{|k,v| [v,k.to_s]}]
    bot.register_application_command(:recommend, 'Recommendation commands',
                                     server_id: server_id) do |cmd|
      cmd.subcommand(:review, 'Post a Review') do |sub|
        sub.string('type', 'Media Type', required: true,
                   choices: media_choices)
        sub.string('title', 'Title', required: true)
        # Choices are string not int because it was causing issues
        # with selecting them on Discord mobile app
        sub.string('score', 'Score', required: true,
                    choices: {'Must Experience': '4',
                              'Decent': '3',
                              'Filet-O-Fish': '2',
                              'Crap': '1'})
        sub.string('review', 'Review', required: true)
      end

      cmd.subcommand(:mention, 'Show a Link to Media') do |sub|
        sub.string('type', 'Media Type', required: true,
                   choices: media_choices)
        sub.string('title', 'Title', required: true)
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
  
  def initialize(bot)
    @db = Airtable.new
    @bot = bot
    @bot.application_command(:recommend).subcommand(:review) do |event|
      begin
        if @db.user_valid? event.user.id
          event.defer
          review_media(event,
                       event.options['type'].to_sym,
                       event.options['title'],
                       event.options['score'].to_i,
                       event.options['review'])
        else
          event.respond(content: "I don't have your airtable email. Please Register your email",
                        ephemeral: true)
        end
      rescue => error
        event.channel.send_message error.message
      end
    end

    @bot.application_command(:recommend).subcommand(:mention) do |event|
      event.defer
      mention_media(event,
                    event.options['type'].to_sym,
                    event.options['title'])
    end

    @bot.application_command(:recommend).subcommand(:register) do |event|
      event.defer
      register_email(event)
    end
  end

  private

  def get_media(event, type, title)
    titles = ListFactory.get_media_list(type, title, SEARCH_LIMIT)
    if !titles || titles.size < 1
      event.edit_response(content: "Couldn't find that title")
      return
    end
    if titles.size > 1
      r = titles.each_with_index.map do |media,index|
        (index+1).to_s + ") #{media.display ? media.display : media.title}"
      end
      response = "Pick Number of Title you are looking for, or 0 to cancel\n"
      response += r.join("\n")
      event.edit_response(content: response)
      event.channel.await!(timeout: 10, author: event.user,contains: /^(\d+)/) do |e|
        n = e.message.text.match(/(\d+)/).captures.first.to_i
        if n.zero?
          event.send_message(content: "Cancelled", ephemeral: true)
        elsif !n.between?(1,titles.size)
          event.send_message(content: "Invalid Number for selection",
                        ephemeral: true)
        else
          t = titles[n-1]
          yield t
        end
        e.message.delete if @bot.bot_user.on(e.server).can_manage_messages?(e.channel)
        true
      end
    elsif titles.size == 1
      t = titles[0]
      yield t
    end
    event.edit_response(content: "Done")
  end

  # Add a link 
  def mention_media(event, type, title)
   get_media(event, type, title) { |m| event.channel.send_message m.url.to_s}
  end
  
  def review_media(event,type,title,score,review)
    get_media(event, type, title) { |m| add_to_db(event,m,score,review) }
  end

  def register_email(event)
    valid_email = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

    begin
      if valid_email.match?(event.options['email'])
        @db.add_user(event.user.id,event.options['email'])
        event.edit_response(content: "Email registered")
      else
        event.edit_response(content: "#{event.options['email']} not a valid email")
      end
    rescue => error
      event.channel.send_message(content:"Couldn't add your email #{event.options['email']}",
                                 ephemeral: true)
    end
  end
  
  # call to add info to Airtable AND print the review to correct channel
  def add_to_db(event,item,score,review)
    @db.add(item,event.user.id,score,review)
    channel = event.server.text_channels.find {|c| c.name == 'recommendations'}
    channel ||= event.channel
    channel.send_message item.url.to_s
    channel.send_message ":pencil:**#{get_author_nick(event)}** *rated this as* "\
                         "**#{@db.get_rating(score)}** #{":star:"*score.to_i}\n"\
                         ":small_blue_diamond:#{review}:small_blue_diamond:"
  end

  # Get best username to display
  def get_author_nick(event)
    member = event.user.on(event.server)
    return member.nick || event.user.name
  end
  
end
