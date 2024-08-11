BROWSER ?= chromium
start: start.sh WebKit Makefile
	./$< &
	@echo Giving server time to start before launching $(BROWSER)
	sleep 5 && $(BROWSER) "$(DEBUGGER)"
WebKit: generate.sh Makefile
	./$<
	$(MAKE) patch
patch:
	sed -i '/ *|| constructor === Float16Array/d' \
	 WebKit/Source/WebInspectorUI/UserInterface/Base/Utilities.js
clean:
	rm -rf WebKit
