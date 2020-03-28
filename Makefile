default: src/**/*.elm examples/*.elm
	@cd examples && elm make TicTacToe.elm --output elm.js && echo "this.Elm.TicTacToe.init();" >>elm.js && node elm.js
