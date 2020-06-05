require 'time'
require 'tzinfo'

class TimeZones
  @default_timezone
  @user_timezones

  def initialize(bot,default_timezone,user_timezones)
    begin
      TZInfo::Timezone.get(@default_timezone)
      @user_timezones.values.uniq.each do |timezone|
        TZInfo::Timezone.get(timezone)
      end
    rescue InvalidTimezoneIdentifier
      # ReportError
      # Don't Load rest
    end
    # respond to each time reported
    
end

  private

  # return an array of the responses of timezones
  def find_all_other_timezones(time)
    timezones = @user_timezones.values << @default
  end

  def user_time(time_string, user)
    timezone = @default_timezone
    timezone = @user_timezones[user] if (@user_timezones.has_key?(user))
    tz = TZInfo::Timezone.get('timezone')
    Time.parse(time_string + " #{timezone}")
  end

  def find_random_timezone()
    
  end
end
