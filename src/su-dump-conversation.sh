#!/bin/bash
# This script dumps recent messages in a specified conversation, in JSON format.
# Requires fairly recent curl.
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36'
SU_URL='https://showup.tv/'
SU_TRANS_URL="${SU_URL}TransList/fullList/lang/pl"
SU_TRANS_LOGIN_URL="${SU_URL}site/log_in?ref=$SU_TRANS_URL"
SU_LOGIN_URL="${SU_URL}site/log_in"
SU_GET_TALK_URL="${SU_URL}site/messages/get_talk/"
SU_COOKIE_JAR=~/.su-cookies.txt
SU_MSGTOOLS_RC=~/.su-messaging-tools-rc
SU_MSGTOOLS_WORKDIR=/run/user/${UID}/su-messaging-tools
SU_MSGTOOLS_LOGIN_HEADERS=${SU_MSGTOOLS_WORKDIR}/login.headers
SU_ADD_COOKIES="--cookie accept_rules=true"

usage() {
	echo $0 'login|talk-get conversation-id'
}

echo_stderr() {
	(>&2 echo "$@")
}

su_login() {
	local SU_LOGIN_POST_DATA="--data-raw email=$SU_LOGIN -d password=$SU_PASS -d submitLogin=Zaloguj"

	curl -A "$UA" $SU_LOGIN_POST_DATA $SU_ADD_COOKIES -e $SU_LOGIN_URL -c $SU_COOKIE_JAR -D $SU_MSGTOOLS_LOGIN_HEADERS --silent -o /dev/null $SU_TRANS_LOGIN_URL

	if grep -q "^Location: $SU_TRANS_URL" $SU_MSGTOOLS_LOGIN_HEADERS ; then
		echo Login OK.
		rm $SU_MSGTOOLS_LOGIN_HEADERS
	else
		echo Login failed, investigate ${SU_MSGTOOLS_LOGIN_HEADERS}.
		exit 20
	fi
}

su_talk_get() {
	mkdir -p ${SU_MSGTOOLS_WORKDIR}
	local TALKFILE=${SU_MSGTOOLS_WORKDIR}/${SU_CONVERSATION_ID}-$(date +%s)

	curl -A "$UA" -v $SU_ADD_COOKIES -b $SU_COOKIE_JAR -o $TALKFILE ${SU_GET_TALK_URL}${SU_CONVERSATION_ID}
}

if [ -f ${SU_MSGTOOLS_RC} ] ; then
	. ${SU_MSGTOOLS_RC}
else
	echo_stderr ${SU_MSGTOOLS_RC} does not exist.
	exit 10
fi

case "$1" in
	login)
		su_login
		;;
	talk-get)
		su_talk_get
		;;
	*)
		usage
		exit 5
		;;
esac

