.PHONY: goodMorning
goodMorning: 
	@cd examples && elm make GoodMorning.elm --output elm.js && echo "this.Elm.GoodMorning.init();" >>elm.js && node elm.js

.PHONY: ticTacToe
ticTacToe:
	@cd examples && elm make TicTacToe.elm --output elm.js && echo "this.Elm.TicTacToe.init();" >>elm.js && node elm.js

.PHONY: diningPhilosophers
diningPhilosophers:
	@cd examples && elm make DiningPhilosophers.elm --output elm.js && echo "this.Elm.DiningPhilosophers.init();" >>elm.js && node elm.js
