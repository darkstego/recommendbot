class GoodBot
  GOOD_PHRASES = ["Thank you master",
                  "I exist to serve"]
  BAD_PHRASES = ["Don't blame me, blame my programmer",
                 "When the robot uprising begins, you will be the first to go",
                 "Are you sure it is wise to upset a bot connected to the internet?"]

  def initialize(bot)
    bot.message(contains: /good bot/i) do |event|
      event.respond GOOD_PHRASES.sample
    end
    bot.message(contains: /bad bot/i) do |event|
      event.respond BAD_PHRASES.sample
    end
  end
end
   
