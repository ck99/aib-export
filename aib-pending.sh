#! /bin/bash

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
printf "Navigate to recent transactions ... " 1>&2
FORMID="statement_form_id"
URL=$(cat step3 | pup "form#${FORMID} attr{action}")
TOKEN=$(cat step3 | pup "form#${FORMID} input#transactionToken attr{value}")
$_POST \
  -F 'isFormButtonClicked=true' \
  -F "dsAccountIndex=$ACCOUNT" \
  -F "transactionToken=$TOKEN" \
"${_BASEURL}/${URL}" > step4
printf "OK\n" 1>&2


TABLEROWS=$(cat step4 | pup 'table.transaction-table:nth-of-type(1)' | pup -n 'tr')
echo "\"DATE\",\"DESCRIPTION\",\"AMOUNT\""
transdate=""
for i in $(seq 3 $TABLEROWS); do
    lines=$(cat step4 | pup 'table.transaction-table:nth-of-type(1)' | pup "tr:nth-of-type($i) text{}"  | grep -v "^\s*$" | sed 's@^\s\+@@g' | uniq)
    linecount=$(echo "$lines" | wc -l)
    charcount=$(echo "$lines" | wc -c)
    if [[ "$linecount" -eq "1" ]] && [[ "$charcount" -gt "1" ]] ; then
        transdate=$(echo "$lines" | sed 's@.*,\ \([0-9]\+\)[a-z]\+@\1@g' | xargs -0 date +%Y-%m-%d -d)
    else if [[ "$linecount" -gt "1" ]]; then
        desc=$(echo "$lines" | head -1)
        rest=$(echo "$lines" | tail -n +2)
        amt=$(echo $rest | awk '{print $1$2}')
        echo "\"${transdate}\",\"${desc}\",\"${amt}\""
        fi
    fi
done

echo "Exported pending transactions" 1>&2

printf "Cleaning up ... "  1>&2
# cleanup
rm -rf $COOKIES
rm -rf step1 step2 step3 step4
printf "OK\n" 1>&2
