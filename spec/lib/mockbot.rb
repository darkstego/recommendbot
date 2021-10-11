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
