default: src/**/*.elm
	@elm make src/Main.elm --output elm.js
	@echo "this.Elm.Main.init();" >>elm.js
	@node elm.js
