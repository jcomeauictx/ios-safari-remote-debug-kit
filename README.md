# Remote Debugging iOS Safari on Linux

Using this project you can debug your websites and web applications running in iOS Safari from a PC running Linux.

It provides a free and up-to-date alternative to the discontinued [remotedebug-ios-webkit-adapter by RemoteDebug](https://github.com/RemoteDebug/remotedebug-ios-webkit-adapter) and is the spiritual successor to the abandoned [webkit-webinspector by Arty Gus](https://github.com/artygus/webkit-webinspector). It is a free and open source alternative to inspect.dev.

**If you are looking for a more modern, self-contained tool built in Go**, check out [Hazel's ios-safari-remote-debug](https://git.gay/besties/ios-safari-remote-debug).

## Requirements for running

- [`ios-webkit-debug-proxy`](https://github.com/google/ios-webkit-debug-proxy)
  - For Linux, please follow the [installation instructions](https://github.com/google/ios-webkit-debug-proxy#linux).
- Python3, the more up-to-date the better.
- A Chromium based browser like Google Chrome, Edge or Opera **or** WebKit
  based browser like Epiphany/GNOME Web

## Requirements for setup

- `git` for downloading WebKit source code
  - On Linux, I suggest installing `git` from your package manager

## Instructions

### Setup

1. Clone this repository to your PC, and `cd` to it.
2. `make`

This will result in the folder `iphone7` being created. It contains the WebInspector files.

The Chrome or Chromium browser will also be launched. It will show you a list
of pages on your phone's Safari browser for debugging. *Do not click* on these
pages, it will not take you to a usable debugger. Instead, replace the "1" at
the end of the URL `http://localhost:8080/Main.html?ws=localhost:9222/devtools/page/1` with the desired page number. Alternatively, you can `make PHONEPAGE=http://localhost:4321/myapp.html` to go directly to the debugger page for that app,
whose URL is shown in your mobile browser.

### Running

1. Plug your iOS device into your PC via USB
3. On the iOS device, confirm that you trust the connection if asked
4. Go to `Settings->Safari->Advanced->Web Inspector` and enable it
5. Open the website you want to debug in Safari
6. On Linux, run `make`. Make sure your iOS device's screen is unlocked.
7. The `ios-webkit-debug-proxy` will show your iOS device's name as connected.
8. The web browser will be launched, pointing to a list of
   debuggable pages. Choose one, let's say "2", and then visit
   `http://localhost:8080/Main.html?ws=localhost:9222/devtools/page/2`.
9. You should be greeted with the WebInspector and can now debug to your heart's content.

### Troubleshooting

- If you get an error like `Uncaught (in promise) Error: 'Browser' domain was not found` from `Connection.js:162` you are trying to inspect a page that is not inspectable  (this could be caused by having Safari extensions installed). Refer to [http://localhost:9222/](http://localhost:9222/) for the available pages and put the correct one at the end of the URL (for example [`http://localhost:8080/Main.html?ws=localhost:9222/devtools/page/2`](http://localhost:8080/Main.html?ws=localhost:9222/devtools/page/2)) for inspecting the second page.
- In case your inspector window stays empty, open the dev tools of your local browser to check the console for errors.
  - If you get an error like `WebSocket connection to 'ws://localhost:9222/devtools/page/1' failed:` from `InspectorFrontendHostStub.js:68`, try unplugging your device and plugging it back in while the site you want to debug is open in Safari. Once you see the ios-webkit-debug-proxy console window display a message like `Connected :9222 to Himbeers iPad (...)`, refresh the inspector page inside your browser (do not use the refresh button on the inspector page, refresh the entire site from your browser).

### Exiting

#### Linux

- Press Ctrl+C in the terminal window to exit

## Known Issues

- "Events" on the "Timelines" tab don't work
- Canvas content doesn't show on the "Graphics" tab
- Minor style glitches due to Webkit vs. Chromium differences

## Notes

If you want to see details about how this was made, you can read a detailed explanation in [`HOW_IT_WORKS.md`](https://github.com/HimbeersaftLP/ios-safari-remote-debug-kit/blob/master/HOW_IT_WORKS.md) (note that this document only describes how the very first version of this tool was created and might not be completely up-to-date).

## Attribution

- This project was made possible thanks to
  - [HimbeersaftLP's original repository](https://github.com/HimbeersaftLP/ios-safari-remote-debug-kit)
  - [webkit-webinspector](https://github.com/artygus/webkit-webinspector) for the idea
  - [ios-webkit-debug-proxy](https://github.com/google/ios-webkit-debug-proxy) for the ios-webkit-debug-proxy tool
  - [WebKit](https://github.com/WebKit/WebKit) for the WebInspector itself
