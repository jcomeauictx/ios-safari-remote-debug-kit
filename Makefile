SHELL := /bin/bash
DEBUG_PROXY_EXE ?= ios_webkit_debug_proxy
# iphone 6 has 12.5.7, closest options are 12.2 and 13.0
PHONE ?= IPHONE7
IPHONE6 := iphone6
IPHONE6_IOS ?= 13.0
# iphone 7 has 15.8.2, closest options are 15.4 and 16.0
IPHONE7 := iphone7
IPHONE7_IOS ?= 15.4
DEBUGGER ?= http://localhost:8080/Main.html?ws=localhost:9222/devtools/page/1
PAUSE ?= false
export DEBUGGER
all: $($(PHONE)).run
%.run: %
	$(MAKE) stop
	$(MAKE) -C $< IOS_VERSION=$($(PHONE)_IOS) DO_PAUSE=$(PAUSE)
	$(MAKE) stop
iphone6 iphone7: src .FORCE
	rm -rf $@
	cp -r src $@
stop: proxy.stop
	httppid=$$(lsof -t -itcp@localhost:8080 -s tcp:listen); \
	if [ "$$httppid" ]; then \
	 echo Stopping server on localhost:8080 >&2; \
	 kill $$httppid; \
	 sleep 1; \
	else \
	 echo Nothing to stop: http server has not been running >&2; \
	fi
	wspid=$$(lsof -t -itcp@localhost:9222 -s tcp:listen); \
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
besties: ios-safari-remote-debug/dist/debug/index.html
%/dist/debug/index.html: %/ios-safari-remote-debug
	cd $(<D) && ./$(<F) build
ios-safari-remote-debug/ios-safari-remote-debug: ios-safari-remote-debug
	cd $< && go build
ios-safari-remote-debug:
	git clone https://git.gay/besties/$@
newserver: ios-safari-remote-debug/dist/debug/index.html proxy
	cd $(<D)/../.. && exec -a isrd ./ios-safari-remote-debug serve &
	chromium http://127.0.0.1:8924/
	read -p '<ENTER> when done: '
	$(MAKE) newserver.stop
newserver.stop: proxy.stop
	if [ "$$(pidof isrd)" ]; then \
	 echo killing ios-safari-remote-debug >&2; \
	 kill $$(pidof isrd); \
	else \
	 echo ios-safari-remote-debug is not running >&2; \
	fi
.FORCE:
