In the Ruby world there are two primary testing frameworks, [rspec](https://relishapp.com/rspec) and [minitest](http://docs.seattlerb.org/minitest/). Rails prefers minitest, but it's not hard at all to swap it out with rspec. Full disclosure, I prefer rspec as of right now, and _most_ of the applications I work with use rspec.

A few weeks ago I ran into an issue. I had an app that my team owned that did use minitest, and it was completely foreign. To complicate things it used Minitest::Spec. This threw me off because not all of the rspec things worked. However, I can see why people like it. Personally, I'd prefer using the core minitest way.

Anyway, I ran into a problem. How do you stub a method that's on a chain?

For example, `car.get_in.buckle_up_buckaroo!`

# First, a note about doubles, stubs, dummies, mocks, spies, fakes, monkey patching, centurions, etc!

I was kidding about centurions. Those don't exist...yet. However, the others do, and they caused me grief. What's the difference? Why would I use one over the other?

Now I may update this as I learn more, but there aren't that many differences. Different frameworks have come up with different names for what they needed. That said, defining each one deserves it's own post. However, for the purposes of this post I'm going to use the definitions in [the post by Ilija Eftimov](https://ieftimov.com/post/test-doubles-theory-minitest-rspec/).

# The problem

I have something I want to test, but it depends on something else. Normally, I'd just stub the needed thing and move on, but what if that thing is owned by another thing. To make matters worse the application is spaghetti code heaven, and I can't trace where things are to do a proper stub? For me I'd rather stub the message chain.

Here is a contrived example.

```ruby
class GrumpyGameFairy < StandardError
  def initialize(msg="Outlook is cloudy, try again later")
    super
  end
end

class GameFairy
  def proclamation
    if mystic_visions == 'The game is in a stalemate!'
      false
    elsif mystic_visions == 'The game is won!'
      true
    else
      raise GrumpyGameFairy
    end
  end

  private

  def mystic_visions
    "Leave me alone!"
  end
end

class GameFairyGateway
  def self.get_fairy
    game_fairy = GameFairy.new()
  end
end

class Game
  def done?
    return GameFairyGateway.get_fairy.proclamation
  end
end
```

Here we have a `Game`, `GameFairyGateway`, and a `GameFairy`. The `GameFairy` is a mysterious resource that we can't understand. How it works is beyond human comprehension. However, it tells us the state of the game (i.e. is the game done), but we fear asking it questions directly. To help us here we've added a `GameFairyGateway` to be our messager for the `GameFairy`'s divine messages.

The problem is that we want to test the game, but let's say we can't efficiently stub the supernatural nature of the `GameFairy` How do we do it? 

# rspec's `receive_message_chain`

```ruby
require_relative '../game'

describe Game do
  subject(:game) { Game.new() }
  describe '#done' do

    context 'the game fairy says there is a tie' do
      it 'returns false' do
        allow(GameFairyGateway).to receive_message_chain(:get_fairy, :proclamation) { false }
        expect(game.done?).to be false 
      end
    end

    context 'the game fairy says the player_1 is the winner' do
      it 'returns true' do
        allow(GameFairyGateway).to receive_message_chain(:get_fairy, :proclamation) { true }
        expect(game.done?).to be true 
      end
    end
  end
end
```

Here we are using 'receive_message_chain' to allow us to base the stub on `GameFairyGateway` even though we are stubbing the `proclamation` method on `GameFairy`. Note that this is really only for legacy code that you're looking to refactor later but for now you can't. Please refer to [rspec's documentation for more information](https://relishapp.com/rspec/rspec-mocks/docs/working-with-legacy-code/message-chains).

# minitest's solution.

```ruby
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
```

This case is slightly different as we don't have an equivalent to the `receive_chained_message` method. In order to do
something similar we need to create two stubs. The first uses the `@game_fairy dummy and is where we stub out the
proclamation method. The second is where we stub out the `get_fairy` method on `GameFairyGateway`. Note that these are
different ways to do the same thing.

You'd be correct in pointing out that we are stubbing out the thing that we "weren't able to understand". Unfortunately,
we don't have another option, so we will have to use a dummy to represent the great power of the GameFairy.

# Running the tests

Running the code here is pretty easy. The code can be found on my [github
profile](https://github.com/danclark5/chained_message_testing). Run `git clone` to get the repo and ensure you have ruby,
minitest, and rspec installed.

From there run the rspec suite with:

```bash
rspec rspec/game_spec.rb
```

The minitest suite with:

```bash
ruby minitest/test_game.rb
```

# Conclusion

`receive_message_chain` is not a method that should be used in new code. It's a code smell that indicates unnecessary
complexity. minitest does not have an equivalent to it, but be wary of needing to stub out too many things in your unit
tests. More is not always better.
