class PartyAnnouncer

  @announce_time = Time.new - (360*60)
  
  def initialize(bot, voice_channel, announce_channel, backoff)
    bot.voice_state_update(channel: voice_channel) do |event|
      if event.channel.users.size >= 2 and Time.now > @announce_time + backoff
        @announce_time = Time.now
        channel = bot.find_channel(announce_channel).first
        bot.send_message channel, "There is a party going on in #{voice_channel}! Hop on in"
      end
    end
  end
end
