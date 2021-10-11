require 'goodbot'
require_relative 'mockbot'

describe GoodBot do
  let(:bot) { MockBot.new }

    subject(:event) { double("event",respond: nil) }
    before(:each) { described_class.new(bot) }
    after(:each) { bot.trigger(event) }
    
    it 'handles (good bot)' do
      allow(event).to receive(:message).and_return("thanks, good bot")
      is_expected.to receive(:respond)
    end

    it 'handles (bad bot)' do
      allow(event).to receive(:message).and_return("you are a bad bot")
      is_expected.to receive(:respond)
    end

    it 'ignore other phrases' do
      allow(event).to receive(:message).and_return("have you watched the gobots?")
      is_expected.to receive(:respond)
    end
end

