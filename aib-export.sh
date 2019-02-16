#! /bin/sh

OUTPUTFILE=$1

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
TOKEN=$(cat step1 | grep transactionToken | sed 's@.*value=\"@@g' | sed 's@\".*@@g')
$_POST \
  -F "transactionToken=$TOKEN" \
  -F "regNumber=$REGNUMBER"    \
  -F 'jsEnabled=TRUE'          \
  -F '_target1=true'           \
$LOGIN > step2
printf "OK\n"


# Parse requested PAC digits and fetch them from credential store
REQDIGIT1=$(cat step2 | grep "/strong"| sed 's@.*\([0-9]\).*@\1@g' | tail -n +1 | head -1)
REQDIGIT2=$(cat step2 | grep "/strong"| sed 's@.*\([0-9]\).*@\1@g' | tail -n +2 | head -1)
REQDIGIT3=$(cat step2 | grep "/strong"| sed 's@.*\([0-9]\).*@\1@g' | tail -n +3 | head -1)
getpac $REQDIGIT1
RESPDIGIT1=$?
getpac $REQDIGIT2
RESPDIGIT2=$?
getpac $REQDIGIT3
RESPDIGIT3=$?
# Respond to second challenge: send specific PAC digits
printf "Send PAC digits: %d, %d and %d ... " ${REQDIGIT1} ${REQDIGIT2} ${REQDIGIT3}
TOKEN=$(cat step2 | grep transactionToken | sed 's@.*value=\"@@g' | sed 's@\".*@@g')
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
TOKEN=$(cat step3 | grep -A 1 "historicaltransactions" | tail -1 | sed 's@.*value=\"@@g' | sed 's@\".*@@g')
$_POST \
  -F 'isFormButtonClicked=true' \
  -F "dsAccountIndex=$ACCOUNT" \
  -F "transactionToken=$TOKEN" \
$TRANSACTIONS > step4
printf "OK\n"


# Get filtered historical transactions
printf "Filter historical transactions ... "
TOKEN=$(cat step4 | grep -B 30 "Apply Filter" | grep "transactionToken" | sed 's@.*value=\"@@g' | sed 's@\".*@@g')
$_POST \
  -F "transactionToken=$TOKEN"  \
  -F "dsAccountIndex=$ACCOUNT"  \
  -F 'startDate.DD=01'          \
  -F 'startDate.MM=01'          \
  -F 'startDate.YYYY=2018'      \
  -F 'endDate.DD=15'            \
  -F 'endDate.MM=02'            \
  -F 'endDate.YYYY=2019'        \
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
TOKEN=$(cat step5 | grep -B 10 "<button>Export</button>" | grep transactionToken | sed 's@.*value=\"@@g' | sed 's@\".*@@g')
$_POST \
  -F "transactionToken=$TOKEN"  \
  -F "dsAccountIndex=$ACCOUNT"  \
  -F 'export=true'              \
  -F 'exportconfirm=true'       \
  -F 'iBankFormSubmission=true' \
  -F '_target0=true'            \
$TRANSACTIONS > $OUTPUTFILE
printf "OK\n"

echo "Exported transactions to ${OUTPUTFILE}"

printf "Cleaning up ... "
# cleanup
rm -rf $COOKIES
rm -rf step1 step2 step3 step4 step5
printf "OK\n"
