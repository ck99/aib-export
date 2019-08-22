#!/bin/sh

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

export CREDENTIALS="${DIR}/credentials.json"
export COOKIES="${DIR}/aibcookies"

export _CURL="curl -s -b $COOKIES -c $COOKIES "
export _POST="${_CURL} -XPOST "

export _BASEURL="https://onlinebanking.aib.ie/inet/roi"
export LOGIN="${_BASEURL}/login.htm"
export INTERRUPTER="${_BASEURL}/logininterrupter.htm"
export TRANSACTIONS="${_BASEURL}/historicaltransactions.htm"
export STATEMENT="${_BASEURL}/statement.htm"

export ACCOUNT="0"
