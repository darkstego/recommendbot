class RecommendBotError < StandardError
  def initialize(msg="My default message", type=:standard)
    @type = type
    super(msg)
  end

  def response()
    text = "I don't know how it is this happen"
    return text
  end
end
