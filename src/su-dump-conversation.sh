#!/bin/bash
UA='User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36'
SU_MAIN_URL='https://showup.tv/site/log_in?ref=https://showup.tv/TransList/fullList/lang/pl'
SU_LOGIN_URL='https://showup.tv/site/log_in'
SU_COOKIE_JAR=~/.su-cookies.txt
SU_MSGTOOLS_RC=~/.su-messaging-tools-rc

echo_stderr() {
	(>&2 echo "$@")
}


if [ -f ${SU_MSGTOOLS_RC} ] ; then
	. ${SU_MSGTOOLS_RC}
else
	echo_stderr ${SU_MSGTOOLS_RC} does not exist.
	exit 10
fi

curl -H "$UA" -v --data-raw "email=$SU_LOGIN" -d "password=$SU_PASS" -d "submitLogin=Zaloguj" --cookie 'accept_rules=true' -e $SU_LOGIN_URL -c $SU_COOKIE_JAR -X POST $SU_MAIN_URL
curl -H "$UA" -v --cookie "accept_rules=true" -b $SU_COOKIE_JAR https://showup.tv/site/messages/get_talk/${SU_CONVERSATION_ID}

