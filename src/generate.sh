#!/usr/bin/env bash

set -euo pipefail

DO_PAUSE=${DO_PAUSE:-true}
DO_FETCH="null"
IOS_VERSION=${IOS_VERSION:-}
SRC=$(readlink -f ../..)
echo Repository sources at $SRC >&2
echo Current directory at $PWD >&2

while getopts ":pfni:" CURRENT_OPT; do
  case "${CURRENT_OPT}" in
    p)
      DO_PAUSE="false"
      ;;
    f)
      if [ "${DO_FETCH}" != "null" ]; then
        echo "Cannot use both -n and -f options at the same time!"
        exit 1
      fi
      DO_FETCH="true"
      ;;
    n)
      if [ "${DO_FETCH}" != "null" ]; then
        echo "Cannot use both -f and -n options at the same time!"
        exit 1
      fi
      DO_FETCH="false"
      ;;
    i)
      IOS_VERSION="${OPTARG}"
      ;;
    *)
      echo "Usage: generate.sh [OPTION]..."
      echo "Download WebKit-WebInspector and apply patches."
      echo ""
      echo "Interactivity options:"
      echo "  -p  Do not pause before exiting script (for usage outside of launching the script from a GUI file explorer)"
      echo ""
      echo "Download options:"
      echo "  -f  Force download WebKit-WebInspector, even if it is already downloaded (for updating)"
      echo "  -n  Never download WebKit-WebInspector, only apply patches to an already downloaded one"
      echo "Default is to download WebKit-WebInspector if it is not already downloaded, else exit."
      echo ""
      echo "Patching options:"
      echo "  -i <version>  Choose iOS version for InspectorBackendCommands.js"
      echo ""
      echo "Project repository: https://github.com/HimbeersaftLP/ios-safari-remote-debug-kit"
      exit
      ;;
  esac
done

# https://stackoverflow.com/a/246128/
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Entering script directory $SCRIPT_DIR"
cd "$SCRIPT_DIR"

if [ "${DO_FETCH}" != "false" ]; then
  
  if [ -d "WebKit" ]; then
    if [ "${DO_FETCH}" = "null" ]; then
      echo "WebKit folder already exists!"
      echo "Delete it or run with -f if you want to update your installation."
      if [ "${DO_PAUSE}" = "true" ]; then
        read -p "Press enter to close this window!"
      fi
      exit 1
    else # DO_FETCH is true
      echo "The folder $(realpath WebKit) and all its content will be erased"
      confirm_response=""
      while [ "${confirm_response}" != "y"  ] && [ "${confirm_response}" != "n" ]; do
        read -p "Confirm? (y/n) " confirm_response
      done
      if [ "${confirm_response}" = "y" ]; then
        rm -rf "WebKit"
      else
        echo "Cannot continue if the folder is not deleted! Exiting."
        exit 1
      fi
    fi
  fi

  echo "Downloading original WebInspector"
  git clone --depth 1 --filter="blob:none" --sparse "https://github.com/WebKit/WebKit.git"
  cd WebKit
  git sparse-checkout set Source/WebInspectorUI/UserInterface
  cd ..
fi

echo "Adding additional code"
cp injectedCode/* WebKit/Source/WebInspectorUI/UserInterface

echo "Referencing additional code in HTML"
sed -i -e ':a' -e 'N' -e '$!ba' \
  -e 's/<script src="Base\/WebInspector.js"><\/script>\r\{0,1\}\n/<script src="Base\/WebInspector.js"><\/script><script src="InspectorFrontendHostStub.js"><\/script><link rel="stylesheet" href="AdditionalStyle.css">/g' \
  WebKit/Source/WebInspectorUI/UserInterface/Main.html

echo "Adding WebSocket init to Main.js"
sed -i -e ':a' -e 'N' -e '$!ba' \
  -e 's/WI.loaded = function()\r\{0,1\}\n{/WI.loaded = function() { WI._initializeWebSocketIfNeeded();/g' \
  WebKit/Source/WebInspectorUI/UserInterface/Base/Main.js

echo "Replacing :matches with :is in CSS"
if grep -qrlZ ':matches' WebKit/Source/WebInspectorUI/UserInterface --include='*.css'; then
  grep -rlZ ':matches' WebKit/Source/WebInspectorUI/UserInterface --include='*.css' | xargs -0 sed -i 's/:matches/:is/g'
fi

echo "Select iOS version for InspectorBackendCommands.js"
protocolPath="WebKit/Source/WebInspectorUI/UserInterface/Protocol"
legacyPath="${protocolPath}/Legacy/iOS"
possibleVersions=$(ls -1 "${legacyPath}" | sort)
possibleVersionsPrint=$(sed ':a;N;$!ba;s/\n/, /g' <<< "${possibleVersions}") # https://stackoverflow.com/a/1252191/11825425
latestVersion="$(ls -1 "${legacyPath}" | sort | tail -n 1)"
if [ "${IOS_VERSION}" = "" ]; then
  selectedVersion="null"
  while ! grep -w -q "^${selectedVersion}$" <<< "${possibleVersions}" && [ "${selectedVersion}" != "" ]; do
    read -p "Choose iOS version (possible options: ${possibleVersionsPrint}) Default: latest (${latestVersion}): " selectedVersion
  done
else
  if ! grep -w -q "^${IOS_VERSION}$" <<< "${possibleVersions}" && [ "${IOS_VERSION}" != "latest" ]; then
    echo "Invalid iOS version (${IOS_VERSION}) provided! Allowed options: ${possibleVersionsPrint}, latest. Exiting."
    exit 1
  fi
  if [ "${IOS_VERSION}" = "latest" ]; then
    selectedVersion=""
  else
    selectedVersion="${IOS_VERSION}"
  fi
fi
if [ "${selectedVersion}" = "" ]; then
  selectedVersion="${latestVersion}"
fi
echo "Copying InspectorBackendCommands.js for iOS ${selectedVersion}"
backendCommandsFile="${legacyPath}/${selectedVersion}/InspectorBackendCommands.js"
echo "  -> Choosing file ${backendCommandsFile}"
cp "${backendCommandsFile}" "${protocolPath}"

echo "Finished!"

if [ "${DO_PAUSE}" = "true" ]; then
  read -p "Press enter to close this window!"
fi
