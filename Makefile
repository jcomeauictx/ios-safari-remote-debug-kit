SHELL := /bin/bash
OWNER_SRC := $(dir $(PWD))
GIT_HTTP_URL := https://github.com/
GIT_GIT_URL := git@github.com:
ifeq ($(USER),jcomeau)
GIT_URL ?= $(GIT_GIT_URL)
else
GIT_URL ?= $(GIT_HTTP_URL)
endif
OWNER := $(notdir $(OWNER_SRC:/=))
DEBUG_PROXY_EXE ?= ios_webkit_debug_proxy
# iphone 6 has 12.5.7, closest options are 12.2 and 13.0
PHONE ?= IPHONE7
IPHONE6 := iphone6
IPHONE6_IOS ?= 13.0
# iphone 7 has 15.8.2, closest options are 15.4 and 16.0
# 15.4 gives "undefined Float16Array error" but not every time (?)
IPHONE7 := iphone7
IPHONE7_IOS ?= 15.4
DEBUGGER ?= http://localhost:8080/Main.html?ws=localhost:9222/devtools/page/1
PAUSE ?= false
BESTIES ?= ../../besties
NEW_DEBUGGER := $(BESTIES)/ios-safari-remote-debug/ios-safari-remote-debug
NEW_DEBUGGER_DIR := $(dir $(NEW_DEBUGGER))
NEW_SERVER := $(notdir $(NEW_DEBUGGER))
USR_SRC ?= $(dir $(BESTIES))
WEBKIT := $(OWNER_SRC:/=)/WebKit
UI_MAIN := Source/WebInspectorUI/UserInterface/Main.html
UI_DIR := $(dir $(UI_MAIN))
PROTOCOL := $(UI_DIR:/=)/Protocol
# use deferred evaluation on anything with VERSION
VERSION = $($(PHONE)_IOS)
BACKEND = $(PROTOCOL)/Legacy/iOS/$(VERSION)/InspectorBackendCommands.js
UI := $(dir $(UI_DIR:/=))
WEBKIT_UI := $(WEBKIT)/$(UI_MAIN)
PYTHON ?= $(shell which python3 python false | head -n 1)
CHROME ?= $(shell which chromium chrome xdg-open false | head -n 1)
DEBUG_PROXY_EXE ?= $(shell which ios-webkit-debug-proxy false | head -n 1)
STRACE ?= strace -v -f -s256 -o/tmp/isrd.strace.log
ifeq ($(SHOWENV),)
export DEBUGGER
else
export
endif
all: $($(PHONE)).run
%.run: %
	$(MAKE) stop
	$(DEBUG_PROXY_EXE) &
	# wait for the webkit proxy to initialize
	while [ -z "$$(lsof -t -itcp:9222 -s tcp:listen)" ]; do \
	 echo Awaiting $(DEBUG_PROXY_EXE)... >&2; \
	 sleep 1; \
	done
	cd $*/WebKit/$(UI_DIR) && $(PYTHON) -m http.server 8080 &
	# wait for the HTTP server to initialize
	while [ -z "$$(lsof -t -itcp:8080 -s tcp:listen)" ]; do \
	 echo Awaiting Python HTTP server... >&2; \
	 sleep 1; \
	done
	-$(STRACE) $(CHROME) $(DEBUGGER) >/tmp/isrd_chrome.log 2>&1
iphone6 iphone7: src
	cp -r src $@
	mkdir -p $@/WebKit/$(UI)
	cp -r $(WEBKIT)/$(UI_DIR:/=) $@/WebKit/$(UI)
	cp -f $@/WebKit/$(BACKEND) $@/WebKit/$(PROTOCOL)/
	cp src/injectedCode/* $@/WebKit/$(UI_DIR)
stop: proxy.stop
	httppid=$$(lsof -t -itcp:8080 -s tcp:listen); \
	if [ "$$httppid" ]; then \
	 echo Stopping server on localhost:8080 >&2; \
	 kill $$httppid; \
	 sleep 1; \
	else \
	 echo Nothing to stop: http server has not been running >&2; \
	fi
	wspid=$$(lsof -t -itcp:9222 -s tcp:listen); \
	if [ "$$wspid" ]; then \
	 echo Stopping server on localhost:9222 >&2; \
	 kill $$wspid; \
	 sleep 1; \
	else \
	 echo Nothing to stop: websocket server has not been running >&2; \
	fi
	iwdppid=$$(lsof -t -itcp:9221 -s tcp:listen); \
	if [ "$$iwdppid" ]; then \
	 echo Stopping server on localhost:9221 >&2; \
	 kill $$iwdppid; \
	 sleep 1; \
	else \
	 echo Nothing to stop: IWDP server has not been running >&2; \
	fi
clean: stop
	rm -rf iphone6 iphone7
proxy:
	if [ -z "$$(lsof -t -itcp:9221 -s tcp:listen)" ]; then \
	 exec -a iwdp $(DEBUG_PROXY_EXE) & \
	fi
proxy.stop:
	if [ "$$(pidof iwdp)" ]; then \
	 echo stopping $(DEBUG_PROXY_EXE) >&2; \
	 kill $$(pidof iwdp); \
	else \
	 echo $(DEBUG_PROXY_EXE) is not running >&2; \
	fi
# more modern golang program referenced in README
besties: $(NEW_DEBUGGER_DIR)/dist/debug/index.html
$(NEW_DEBUGGER_DIR)/dist/debug/index.html: $(NEW_DEBUGGER)
	cd $(<D) && ./$(<F) build
$(NEW_DEBUGGER): $(NEW_DEBUGGER_DIR)/.git
	cd $(<D) && go build
$(NEW_DEBUGGER_DIR)/.git: $(BESTIES)
	cd $< && git clone https://git.gay/besties/$(NEW_SERVER)
$(BESTIES): $(USR_SRC)
	if [ -w "$<" ]; then \
	 mkdir -p $@; \
	else \
	 echo cannot create directory $@ >&2; \
	 echo 'try with `sudo` or `make BESTIES=. $(NEW_DEBUGGER)`' >&2; \
	 false; \
	fi
newserver: $(NEW_DEBUGGER_DIR)/dist/debug/index.html proxy
	if [ -z "$(CHROME)" ]; then \
	 echo cannot find chrome or similar browser >&2; \
	 false; \
	fi
	cd $(NEW_DEBUGGER_DIR) && exec -a isrd ./$(NEW_SERVER) serve &
	$(CHROME) http://127.0.0.1:8924/
	read -p '<ENTER> when done: '
	$(MAKE) newserver.stop
newserver.stop: proxy.stop
	if [ "$$(pidof isrd)" ]; then \
	 echo killing $(NEW_SERVER) >&2; \
	 kill $$(pidof isrd); \
	else \
	 echo $(NEW_SERVER) is not running >&2; \
	fi
env:
ifeq ($(SHOWENV),)
	make SHOWENV=1 $@
else
	env | grep -v '^LS_COLORS='
endif
$(WEBKIT):
	cd $(OWNER_SRC) && git clone --depth 1 --filter="blob:none" \
	 --sparse "$(GIT_URL)$(OWNER)/WebKit"
$(WEBKIT_UI): | $(WEBKIT)
	cd $| && git sparse-checkout set $(dir $(UI_MAIN))
webkit: $(WEBKIT_UI)   # just for testing
.FORCE:
