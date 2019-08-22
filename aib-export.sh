#! /bin/bash

RANGESTART=$1
SYEAR=$(echo ${RANGESTART} | cut -d- -f1)
SMONTH=$(echo ${RANGESTART} | cut -d- -f2)
SDAY=$(echo ${RANGESTART} | cut -d- -f3)

RANGEEND=$2
EYEAR=$(echo ${RANGEEND} | cut -d- -f1)
EMONTH=$(echo ${RANGEEND} | cut -d- -f2)
EDAY=$(echo ${RANGEEND} | cut -d- -f3)

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

${DIR}/aib-login.sh

source ${DIR}/vars.sh

# Navigate to recent transactions page
printf "Navigate to historical transactions ... " 1>&2
FORMID="historicalstatement_form_id"
URL=$(cat step3 | pup "form#${FORMID} attr{action}")
TOKEN=$(cat step3 | pup "form#${FORMID} input#transactionToken attr{value}")
$_POST \
  -F 'isFormButtonClicked=true' \
  -F "dsAccountIndex=$ACCOUNT" \
  -F "transactionToken=$TOKEN" \
"${_BASEURL}/${URL}" > step4
printf "OK\n" 1>&2

# Get filtered historical transactions
printf "Filter historical transactions ... " 1>&2
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
printf "OK\n" 1>&2

# Export historical transactions
printf "Export historical transactions ... " 1>&2
TOKEN=$(cat step5 | pup 'form#historicalTransactionsCommand json{}' | jq -r '.[0].children|map(select(.id == "transactionToken"))[0].value')
$_POST \
  -F "transactionToken=$TOKEN"  \
  -F "dsAccountIndex=$ACCOUNT"  \
  -F 'export=true'              \
  -F 'exportconfirm=true'       \
  -F 'iBankFormSubmission=true' \
  -F '_target0=true'            \
$TRANSACTIONS #> $OUTPUTFILE
printf "OK\n" 1>&2

echo "Exported transactions between ${RANGESTART} and ${RANGEEND}" 1>&2

printf "Cleaning up ... " 1>&2
# cleanup
rm -rf $COOKIES
rm -rf step1 step2 step3 step3a step4 step5
printf "OK\n" 1>&2
