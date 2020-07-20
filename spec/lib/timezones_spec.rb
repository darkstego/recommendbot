require 'timezones.rb'

class MockBot

  def initialize
  end

  def message(contains: nil , &block)
    @regex = contains
    @block = block
  end

  def trigger (event)
    @block.call(event)
  end
end

describe TimeZones do
  let(:event) { double("event",respond: nil) }
  let(:user_default) {double("user", id: 1111)}
  let(:user_custom) {double("custom_user", id: 1234)}
  let(:bot) { MockBot.new }
  subject { described_class.new(bot,"Asia/Riyadh",{"1234": "America/New_York"})}

  it 'responds when message has HH:MM time' do
    allow(event).to receive(:message).and_return("Lets do something at 12:34")
    allow(event).to receive(:user).and_return(user_default)
    expect(event).to receive(:respond).with(match(/12:34 in Riyadh/))
    subject
    bot.trigger(event)
  end

  it 'handles custom user timezone' do
    allow(event).to receive(:message).and_return("Lets do something at 12:34")
    allow(event).to receive(:user).and_return(user_custom)
    expect(event).to receive(:respond).with(match(/12:34 in New York/))
    subject
    bot.trigger(event)
  end

  it 'responds when message has HH:MM AM/PM time' do
    allow(event).to receive(:message).and_return("Lets meet at 3:20 pm")
    allow(event).to receive(:user).and_return(user_default)
    expect(event).to receive(:respond).with(match(/15:20 in Riyadh/))
    subject
    bot.trigger(event)
  end

   it 'responds when message has at HH' do
    allow(event).to receive(:message).and_return("Lets meet at 3")
    allow(event).to receive(:user).and_return(user_default)
    expect(event).to receive(:respond).with(match(/15:00 in Riyadh/))
    subject
    bot.trigger(event)
  end

  it 'doesnt respond when no time is mentioned' do
    allow(event).to receive(:message).and_return("How about a party later")
    allow(event).to receive(:user).and_return(user_default)
    expect(event).to receive(:respond).never
    subject
    bot.trigger(event)
  end

  it 'doesnt respond when talking about percentages' do
    allow(event).to receive(:message).and_return("Progress at 33%")
    allow(event).to receive(:user).and_return(user_default)
    expect(event).to receive(:respond).never
    subject
    bot.trigger(event)
  end

  #private method tests 
  it 'finds explicit HH:MM times' do
    expect(subject.send(:find_time_in_message,"how about at 12:30")).to eq(Time.parse "12:30")
    expect(subject.send(:find_time_in_message,"maybe 3:15 will be good")).to eq(Time.parse "3:15")
  end

  it 'finds HH:MM AM/PM formatted times' do
    expect(subject.send(:find_time_in_message,"The game start at 4:30PM")).to eq(Time.parse "4:30 PM")
    expect(subject.send(:find_time_in_message,"Is 11:19 AM good?")).to eq(Time.parse "11:19 AM")
    expect(subject.send(:find_time_in_message,"I wanna meet at 3:12 pm")).to eq(Time.parse "3:12 PM")

  end

  it 'find HH AM/PM formatted times' do
    expect(subject.send(:find_time_in_message,"we meet at 3 pm")).to eq(Time.parse "3:00 PM")
    expect(subject.send(:find_time_in_message,"it happened at 12am")).to eq(Time.parse "12:00 AM")
  end

  it 'finds the phrase (at HH)' do
    expect(subject.send(:find_time_in_message,"why don't we do it at 3")).to eq(Time.parse "3:00 PM")
    expect(subject.send(:find_time_in_message,"I will be free at 5")).to eq(Time.parse "5:00 PM")  end
  
  it 'should not find time in strings without time' do
    expect(subject.send(:find_time_in_message,"How is the weather?")).to be_nil
    expect(subject.send(:find_time_in_message,"Did you see ep 3")).to be_nil
    expect(subject.send(:find_time_in_message,"It cost 500 I think")).to be_nil
  end

end
