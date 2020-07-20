# coding: utf-8
require 'time'
require 'tzinfo'

class TimeZones
  TIME_FORMAT = '%H:%M'

  def initialize(bot,default_timezone,user_timezones)
    begin
      @default_timezone = TZInfo::Timezone.get(default_timezone)
      @user_timezones = Hash[user_timezones.map {|key,tz| [key,TZInfo::Timezone.get(tz)] }]
    rescue TZInfo::InvalidTimezoneIdentifier
      # ReportError
      # Don't Load rest
    end
    # respond to each time reported
    bot.message(contains: /\d/) do |event|
      parse_message(event.message.to_s, event.user.id, event)
    end
  end

  private

  def parse_message(message,user, event)
    time = find_time_in_message(message)
    if time
      tz = user_timezone(user)
      time = replace_timezone(time,tz)
      other_tzs = find_all_other_timezones(tz)
      response = "#{time.strftime(TIME_FORMAT)} in #{tz.friendly_identifier(true)} is "
      other_tzs.each do |user_tz|
        user_time = user_tz.to_local(time)
        response += "#{user_time.strftime(TIME_FORMAT)} in #{user_tz.friendly_identifier(true)}, "
      end
      random_tz = find_random_timezone
      random_time = random_tz.to_local(time)
      response += "and " unless other_tzs.empty?
      response += "#{random_time.strftime(TIME_FORMAT)} in #{random_tz.friendly_identifier(true)}"
      event.respond response
    end
  end

  # return an array of all other users timezones
  def find_all_other_timezones(tz)
    timezones = @user_timezones.values << @default_timezone
    timezones.delete(tz)
    return timezones
  end

  def find_random_timezone()
    TZInfo::Timezone.get(TZInfo::Timezone.all_identifiers.sample)
  end

  def user_timezone(user)
    user = user.to_s.to_sym
    @user_timezones.has_key?(user) ? @user_timezones[user] : @default_timezone
  end

  def replace_timezone(time,tz)
    tz.local_time(time.year,time.month, time.day, time.hour, time.min, time.sec)
  end
  
  # If only single number given assume they mean PM
  # Returns nil if not time found
  def find_time_in_message(text)
    regex_array = [/(1[0-2]|0?[1-9]):([0-5]?[0-9])(\s?[AP]M)/i,
                   /(2[0-3]|[01]?[0-9]):([0-5]?[0-9])/,
                   /(1[0-2]|[1-9])\s?[AP]M/i,
                  /at\s{0,2}(1[0-2]|[1-9])(?:$|[.,\s])/i]
    regex = regex_array.find { |reg| text[reg]}
    if regex
      time = regex == regex_array.last ? text[regex,1] + " PM" : text[regex]
      Time.parse time
    end
  end
end
