#! /bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

source ${DIR}/vars.sh

getpac()
{
  REQDIGIT=$(expr $1 - 1)
  return $(jq ".PAC[${REQDIGIT}]" $CREDENTIALS)
}

# Read Credentials
REGNUMBER=$(jq -r '.registrationNumber' $CREDENTIALS)

rm -rf $COOKIES

# Fetch initial Login screen
printf "Fetch login screen ... " 1>&2
$_CURL $LOGIN > step1
printf "OK\n" 1>&2


# Respond to first challenge: send registration number
printf "Send registration number ... " 1>&2
TOKEN=$(cat step1 | pup 'form#loginstep1Form input#transactionToken attr{value}')
$_POST \
  -F "transactionToken=$TOKEN" \
  -F "regNumber=$REGNUMBER"    \
  -F 'jsEnabled=TRUE'          \
  -F '_target1=true'           \
$LOGIN > step2
printf "OK\n" 1>&2


# Parse requested PAC digits and fetch them from credential store
REQDIGIT1=$(cat step2 | pup 'form#loginstep2Form div.x3-login:nth-of-type(1) label text{}' | grep [0-9] | sed 's@\s*@@g')
REQDIGIT2=$(cat step2 | pup 'form#loginstep2Form div.x3-login:nth-of-type(2) label text{}' | grep [0-9] | sed 's@\s*@@g')
REQDIGIT3=$(cat step2 | pup 'form#loginstep2Form div.x3-login:nth-of-type(3) label text{}' | grep [0-9] | sed 's@\s*@@g')
getpac $REQDIGIT1
RESPDIGIT1=$?
getpac $REQDIGIT2
RESPDIGIT2=$?
getpac $REQDIGIT3
RESPDIGIT3=$?
# Respond to second challenge: send specific PAC digits
printf "Send PAC digits: %d, %d and %d ... " ${REQDIGIT1} ${REQDIGIT2} ${REQDIGIT3} 1>&2
TOKEN=$(cat step2 | pup 'form#loginstep2Form input#transactionToken attr{value}')
$_POST \
  -F 'jsEnabled=TRUE'                   \
  -F "transactionToken=$TOKEN"          \
  -F "pacDetails.pacDigit1=$RESPDIGIT1" \
  -F "pacDetails.pacDigit2=$RESPDIGIT2" \
  -F "pacDetails.pacDigit3=$RESPDIGIT3" \
  -F '_finish=true'                     \
$LOGIN > step3
printf "OK\n" 1>&2
