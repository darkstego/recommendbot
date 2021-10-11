# coding: utf-8
# This is an advanced recommendation bot.... for recommendations
$:.unshift File.expand_path("../lib", __FILE__)

require 'rubygems'
require 'bundler/setup'
require 'config'
require 'discordrb'
require 'recommendation'
require 'partyannouncer'
require 'timezones'
require 'goodbot'

settings_file = File.expand_path("../config/settings.yml", __FILE__)
secrets_file = File.expand_path("../config/secrets.yml", __FILE__)
Config.load_and_set_settings(settings_file,secrets_file)
secrets = Settings.secrets.to_h

bot = Discordrb::Bot.new(token: secrets[:discord_token], client_id: secrets[:discord_client_id])

bot.mention do |event|
  event.user.pm('You have mentioned me!')
end

Recommendations.new(bot,secrets).start
PartyAnnouncer.new(bot,
                   Settings.party_voice_channel,
                   Settings.party_announce_channel,
                   Settings.party_backoff)
TimeZones.new(bot,Settings.default_tz,Settings.user_tz.to_h)
GoodBot.new(bot)

# This method call has to be put at the end of your script, it is what makes the bot actually connect to Discord. If you
# leave it out (try it!) the script will simply stop and the bot will not appear online.
bot.run
