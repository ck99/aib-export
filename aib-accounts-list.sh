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

NUMBEROFACCOUNTS=$(cat step3 | pup -n '.accounts-list dl')

echo "\"INDEX\",\"NAME\",\"BALANCE\""
for i in $(seq 1 $NUMBEROFACCOUNTS); do
    INDEX=$(expr $i - 1)
    NAME=$(cat step3 | pup '.accounts-list dl' | pup "dl:nth-of-type($i)" | pup '.account-name text{}' | grep -v "^\s*$" | sed 's@^\s\+@@g')
    BALANCE=$(cat step3 | pup '.accounts-list dl' | pup "dl:nth-of-type($i)" | pup '.account-balance .a-amount text{}' | grep -v "^\s*$" | sed 's@^\s\+@@g')

    echo "${INDEX},\"${NAME}\",\"${BALANCE}\""
done

echo "Exported accounts list"

printf "Cleaning up ... " 1>&2
# cleanup
rm -rf $COOKIES
rm -rf step1 step2 step3
printf "OK\n" 1>&2
