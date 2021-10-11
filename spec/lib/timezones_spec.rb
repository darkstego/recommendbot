require 'timezones.rb'
require_relative 'mockbot'

describe TimeZones do
  let(:bot) { MockBot.new }

  describe "Interface" do
    subject(:event) { double("event",respond: nil) }
    let(:user_default) {double("user", id: 1111)}
    let(:user_custom) {double("custom_user", id: 1234)}
    before(:each) do
      described_class.new(bot,"Asia/Riyadh",{"1234": "America/New_York"})
      allow(event).to receive(:user).and_return(user_default)
    end
    after(:each) {bot.trigger(event)}
    
    it 'handles (HH:MM)' do
      allow(event).to receive(:message).and_return("Lets do something at 12:34")
      is_expected.to receive(:respond).with(match(/12:34 in Riyadh/))
    end

    it 'handles custom user timezone' do
      allow(event).to receive(:message).and_return("Lets do something at 12:34")
      allow(event).to receive(:user).and_return(user_custom)
      is_expected.to receive(:respond).with(match(/12:34 in New York/))
    end

    it 'handles (HH:MM PM)' do
      allow(event).to receive(:message).and_return("Lets meet at 3:20 pm")
      is_expected.to receive(:respond).with(match(/15:20 in Riyadh/))
    end

    it 'handles (HH:MM AM)' do
      allow(event).to receive(:message).and_return("Lets meet at 3:20 am")
      is_expected.to receive(:respond).with(match(/3:20 in Riyadh/))
    end


    it 'handles (at HH)' do
      allow(event).to receive(:message).and_return("Lets meet at 3")
      is_expected.to receive(:respond).with(match(/15:00 in Riyadh/))
    end

    it 'handles (around HH)' do
      allow(event).to receive(:message).and_return("I can do tonight.. Around 9")
      is_expected.to receive(:respond).with(match(/21:00 in Riyadh/))
    end

    it 'handles (at HH, then more text)' do
      allow(event).to receive(:message).and_return("Lets meet at 3, then decide")
      is_expected.to receive(:respond).with(match(/15:00 in Riyadh/))
    end

    it 'handles (by HHMM)' do
      allow(event).to receive(:message).and_return("I'll be free by 930 I assume")
      is_expected.to receive(:respond).with(match(/21:30 in Riyadh/))
    end

    it 'handles (at HH then space and more text)' do
      allow(event).to receive(:message).and_return("Lets meet at 3 then decide")
      is_expected.to receive(:respond).with(match(/15:00 in Riyadh/))
    end

    it 'does not respond when no time is mentioned' do
      allow(event).to receive(:message).and_return("How about a party later")
      is_expected.to receive(:respond).never
    end

    it 'does n0t respond when talking about percentages' do
      allow(event).to receive(:message).and_return("Progress at 12%")
      is_expected.to receive(:respond).never
    end
  end
  #private method tests
  describe "Private Method Tests" do
    subject {described_class.new(bot,"Asia/Riyadh",{"1234": "America/New_York"})}
    it 'finds explicit HH:MM times' do
      expect(subject.send(:find_time_in_message,"how about at 12:30")).to eq(Time.parse "12:30")
      expect(subject.send(:find_time_in_message,"maybe 3:15 will be good")).to eq(Time.parse "3:15 pm")
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
      expect(subject.send(:find_time_in_message,"I will be free at 5")).to eq(Time.parse "5:00 PM")
    end
    
    it 'should not find time in strings without time' do
      expect(subject.send(:find_time_in_message,"How is the weather?")).to be_nil
      expect(subject.send(:find_time_in_message,"Did you see ep 3")).to be_nil
      expect(subject.send(:find_time_in_message,"It cost 500 I think")).to be_nil
    end
  end
end
