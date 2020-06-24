require 'bot_helper'

class BotHelper

  attr_accessor :text
  attr_reader :receive
  
  def initialize()
    @message = nil
    @regex = nil
    @block = nil
    @event = double('event')
    @message = double('message')
    allow(@event).to receive(:message) {@message}
    allow(@message).to receive(:text) {@text}
  end

  def message(contains:,&block)
    @regex = contains
    @block=block
  end
  
  def send_message(channel,message)
    @message = message
  end

  def trigger_message(message)
    @text = message
    if @regex ~= message
      @block.call(@event)
    end
  end
end

describe TimeZones do
  context "When testing the TimeZones class" do
    before(:each) do
      @bot = BotHelper.new()
      @timezones = TimeZones.new(bot)
    end

    it "should read HH:MM notation" do
      @bot.trigger_message "Meet at 12:01 today"
      expect(@bot.receive).to be_kind_of(String)
      end
  end
end
