#!/bin/bash

TARGET=$1
WORDLIST=${2:-"method.txt"}

if [ -z "$TARGET" ]; then
	echo "Usage: $0 <target_url> [method_wordlist]"
	exit 1
fi

echo "[#] testing supported method via OPTIONS\n"
curl -s -I -X OPTIONS "$TARGET" | grep -i "Allow"

echo -e "[#] fuzzing http method from wordlist: $WORDLIST\n"
while read METHOD; do
	echo -e "[*] testing $METHOD method...\n"
	curl -s -o /dev/null -w "%{http_code}\n" -X "$METHOD" "$TARGET"
done < "$WORDLIST"

echo -e "[#] testing for method override X-HTTP-Method-Override ...\n"
curl -s -X POST "$TARGET" -H "X-HTTP-Method-Override: DELETE" -d "test=data" -v 2>&1 | grep -E "< HTTP|> POST|Override"

echo -e "common override header with GET to PUT...\n"
curl -s -X GET "$TARGET" \
	-H "X-HTTP-Method-Override: PUT" \
	-H "X-Method-Override: PUT" \
	-H "X-Original-Method: PUT" \
	-d "data=test" \
	-v 2>&1 | grep -E "< HTTP|> GET|Override"

echo -e "[#] DONE"
