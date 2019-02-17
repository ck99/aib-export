#!/bin/sh

export CREDENTIALS="credentials.json"
export COOKIES="aibcookies"

export _CURL="curl -s -b $COOKIES -c $COOKIES "
export _POST="${_CURL} -XPOST "

export _BASEURL="https://onlinebanking.aib.ie/inet/roi"
export LOGIN="${_BASEURL}/login.htm"
export TRANSACTIONS="${_BASEURL}/historicaltransactions.htm"
export STATEMENT="${_BASEURL}/statement.htm"

export ACCOUNT="0"