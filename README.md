# aib.ie - Automated Transaction Export

## Disclaimer!
It's not a complicated script, but obviously you take and use it at your own risk. This work was inspired by https://github.com/owenobyrne/aib-internet-banking-api. This script is known to work correctly as at 2019-02-16, but there is no error detection/handling/recovery, so it might blow up in your face. It took me just under an hour to build this from scratch, so it's really not all that complicated. You'll notice a repeating pattern of :
   * fetch a page 
    * extract the appropriate 'transactionToken' for the next action
    * fetch the next page

It should be possible to re-work this script to achieve whatever you need to do, but at some point, it would get a bit ridiculous and you'd probably be better off using something like the solution mentioned above. 

## Dependencies
To make this run, you'll need:
 * curl
 * jq (https://github.com/stedolan/jq)
 * a bank account with Internet Banking enabled at aib.ie
 * your access credentials for said Internet Banking

## Setup
1. Clone this repository
2. Copy the included credentials-sample.json file to credentials.json and edit it to insert the appropriate values
	
	`$ cp credentials-sample.json credentials.json; vim credentials.json`
3. Execute the script like so:
	
	`$ ./aib-export.sh exported_transactions.csv 2018-01-01 2018-12-31`

## Known Issues
 * AIB Internet Banking has a 24 month historical limit on transaction export.
	 * Not much we can do about that: it is what it is.
 * I've so far only used the script to export the transactions from a single account. This account happens to be the first one in the sort order for me.
	 * I suspect that the account to use is parameterised by 'dsAccountIndex', but I have not tested or confirmed this.