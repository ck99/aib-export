#! /bin/bash

./aib-login.sh

source vars.sh

# Navigate to recent transactions page
printf "Navigate to recent transactions ... "
FORMID="statement_form_id"
URL=$(cat step3 | pup "form#${FORMID} attr{action}")
TOKEN=$(cat step3 | pup "form#${FORMID} input#transactionToken attr{value}")
$_POST \
  -F 'isFormButtonClicked=true' \
  -F "dsAccountIndex=$ACCOUNT" \
  -F "transactionToken=$TOKEN" \
"${_BASEURL}/${URL}" > step4
printf "OK\n"


TABLEROWS=$(cat step4 | pup 'table.transaction-table:nth-of-type(1)' | pup -n 'tr')

for i in $(seq 3 $TABLEROWS); do
    lines=$(cat step4 | pup 'table.transaction-table:nth-of-type(1)' | pup "tr:nth-of-type($i) text{}"  | grep -v "^\s*$" | sed 's@^\s\+@@g' | uniq)
    echo $lines
done