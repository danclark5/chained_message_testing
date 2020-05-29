require "minitest/autorun"
require_relative '../game'

class TestGame < Minitest::Test
  def setup
    @game = Game.new
    @game_fairy = Object.new
  end

  def test_that_game_is_not_done

    def @game_fairy.proclamation
      false
    end

    GameFairyGateway.stub :get_fairy, @game_fairy do
      assert_equal false, @game.done? 
    end
  end

  def test_that_game_is_done

    def @game_fairy.proclamation
      true 
    end

    GameFairyGateway.stub :get_fairy, @game_fairy do
      assert_equal true, @game.done? 
    end
  end
end
