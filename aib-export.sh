#! /bin/sh

OUTPUTFILE=$1

RANGESTART=$2
SYEAR=$(echo ${RANGESTART} | cut -d- -f1)
SMONTH=$(echo ${RANGESTART} | cut -d- -f2)
SDAY=$(echo ${RANGESTART} | cut -d- -f3)

RANGEEND=$3
EYEAR=$(echo ${RANGEEND} | cut -d- -f1)
EMONTH=$(echo ${RANGEEND} | cut -d- -f2)
EDAY=$(echo ${RANGEEND} | cut -d- -f3)

ACCOUNT="0"

CREDENTIALS="credentials.json"
getpac()
{
  REQDIGIT=$(expr $1 - 1)
  return $(jq ".PAC[${REQDIGIT}]" $CREDENTIALS)
}

# Read Credentials
REGNUMBER=$(jq -r '.registrationNumber' $CREDENTIALS)
COOKIES="aibcookies"
rm -rf $COOKIES

_CURL="curl -s -b $COOKIES -c $COOKIES "
_POST="${_CURL} -XPOST "

_BASEURL="https://onlinebanking.aib.ie/inet/roi"
LOGIN="${_BASEURL}/login.htm"
TRANSACTIONS="${_BASEURL}/historicaltransactions.htm"




# Fetch initial Login screen
printf "Fetch login screen ... "
$_CURL $LOGIN > step1
printf "OK\n"


# Respond to first challenge: send registration number
printf "Send registration number ... "
TOKEN=$(cat step1 | pup 'form#loginstep1Form input#transactionToken attr{value}')
$_POST \
  -F "transactionToken=$TOKEN" \
  -F "regNumber=$REGNUMBER"    \
  -F 'jsEnabled=TRUE'          \
  -F '_target1=true'           \
$LOGIN > step2
printf "OK\n"


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
printf "Send PAC digits: %d, %d and %d ... " ${REQDIGIT1} ${REQDIGIT2} ${REQDIGIT3}
TOKEN=$(cat step2 | pup 'form#loginstep2Form input#transactionToken attr{value}')
$_POST \
  -F 'jsEnabled=TRUE'                   \
  -F "transactionToken=$TOKEN"          \
  -F "pacDetails.pacDigit1=$RESPDIGIT1" \
  -F "pacDetails.pacDigit2=$RESPDIGIT2" \
  -F "pacDetails.pacDigit3=$RESPDIGIT3" \
  -F '_finish=true'                     \
$LOGIN > step3
printf "OK\n"


# Navigate to historical transactions page
printf "Navigate to historical transactions ... "
URL=$(cat step3 | pup 'form#historicalstatement_form_id attr{action}')
TOKEN=$(cat step3 | pup 'form#historicalstatement_form_id input#transactionToken attr{value}')
$_POST \
  -F 'isFormButtonClicked=true' \
  -F "dsAccountIndex=$ACCOUNT" \
  -F "transactionToken=$TOKEN" \
"${_BASEURL}/${URL}" > step4
printf "OK\n"


# Get filtered historical transactions
printf "Filter historical transactions ... "
TOKEN=$(cat step4 | pup 'form#historicalTransactionsCommand json{}' | jq -r '.[1].children[-1].children|map(select(.id == "transactionToken"))[0].value')
$_POST \
  -F "transactionToken=$TOKEN"  \
  -F "dsAccountIndex=$ACCOUNT"  \
  -F "startDate.DD=$SDAY"       \
  -F "startDate.MM=$SMONTH"     \
  -F "startDate.YYYY=$SYEAR"    \
  -F "endDate.DD=$EDAY"         \
  -F "endDate.MM=$EMONTH"       \
  -F "endDate.YYYY=$EYEAR"      \
  -F 'errFlag=false'            \
  -F 'minAmount=0.00'           \
  -F 'maxAmount=999999999.00'   \
  -F 'categoryDebit=true'       \
  -F '_categoryDebit=on'        \
  -F 'atm=true'                 \
  -F '_atm=on'                  \
  -F 'cheque=true'              \
  -F '_cheque=on'               \
  -F 'debit=true'               \
  -F '_debit=on'                \
  -F 'billPayment=true'         \
  -F '_billPayment=on'          \
  -F 'other=true'               \
  -F '_other=on'                \
  -F 'categoryCredit=true'      \
  -F '_categoryCredit=on'       \
  -F 'lodgement=true'           \
  -F '_lodgement=on'            \
  -F 'creditOther=true'         \
  -F '_creditOther=on'          \
  -F 'searchKeywords='          \
  -F 'filtertx=true'            \
  -F 'export=false'             \
  -F 'iBankFormSubmission=true' \
  -F 'sortBy=false'             \
$TRANSACTIONS > step5
printf "OK\n"


# Export historical transactions
printf "Export historical transactions ... "
TOKEN=$(cat step5 | pup 'form#historicalTransactionsCommand json{}' | jq -r '.[0].children|map(select(.id == "transactionToken"))[0].value')
$_POST \
  -F "transactionToken=$TOKEN"  \
  -F "dsAccountIndex=$ACCOUNT"  \
  -F 'export=true'              \
  -F 'exportconfirm=true'       \
  -F 'iBankFormSubmission=true' \
  -F '_target0=true'            \
$TRANSACTIONS > $OUTPUTFILE
printf "OK\n"

echo "Exported transactions between ${RANGESTART} and ${RANGEEND} to ${OUTPUTFILE}"

printf "Cleaning up ... "
# cleanup
rm -rf $COOKIES
rm -rf step1 step2 step3 step4 step5
printf "OK\n"
