BROWSER ?= chromium
start: start.sh WebKit Makefile
	./$< &
	@echo Giving server time to start before launching $(BROWSER)
	sleep 5 && $(BROWSER) "$(DEBUGGER)"
WebKit: generate.sh Makefile
	./$<
clean:
	rm -rf WebKit
