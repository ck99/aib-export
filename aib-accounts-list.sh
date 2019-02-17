#! /bin/bash

OUTPUTFILE=$1

./aib-login.sh

source vars.sh

NUMBEROFACCOUNTS=$(cat step3 | pup -n '.accounts-list dl')

echo "\"INDEX\",\"NAME\",\"BALANCE\"" > $OUTPUTFILE
for i in $(seq 1 $NUMBEROFACCOUNTS); do
    INDEX=$(expr $i - 1)
    NAME=$(cat step3 | pup '.accounts-list dl' | pup "dl:nth-of-type($i)" | pup '.account-name text{}' | grep -v "^\s*$" | sed 's@^\s\+@@g')
    BALANCE=$(cat step3 | pup '.accounts-list dl' | pup "dl:nth-of-type($i)" | pup '.account-balance .a-amount text{}' | grep -v "^\s*$" | sed 's@^\s\+@@g')

    echo "${INDEX},\"${NAME}\",\"${BALANCE}\"" >> $OUTPUTFILE
done

echo "Exported accounts list to ${OUTPUTFILE}"

printf "Cleaning up ... "
# cleanup
rm -rf $COOKIES
rm -rf step1 step2 step3
printf "OK\n"
