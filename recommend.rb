# coding: utf-8
# This is an advanced recommendation bot.... for recommendations
$:.unshift File.expand_path("../lib", __FILE__)
$:.unshift File.expand_path("../config", __FILE__)


require 'rubygems'
require 'bundler/setup'
require 'config'
require 'discordrb'
require 'recommendation'
require 'partyannouncer'
require 'timezones'



bot = Discordrb::Bot.new token: configatron.token, client_id: configatron.client_id

bot.mention do |event|
  # initial message.
  event.user.pm('You have mentioned me!')
end

Recommendations.new(bot)
PartyAnnouncer.new(bot, "Dewaniya", "general", 90*60)
TimeZones.new(bot,"Asia/Riyadh",{})


# This method call has to be put at the end of your script, it is what makes the bot actually connect to Discord. If you
# leave it out (try it!) the script will simply stop and the bot will not appear online.
bot.run
