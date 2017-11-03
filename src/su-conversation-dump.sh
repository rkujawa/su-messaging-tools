#!/bin/bash
# This script dumps recent messages in a specified conversation, in JSON format.
# Requires fairly recent curl.
. $(dirname $0)/su-conversation.subr

UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36'
SU_URL='https://showup.tv/'
SU_TRANS_URL="${SU_URL}TransList/fullList/lang/pl"
SU_TRANS_LOGIN_URL="${SU_URL}site/log_in?ref=$SU_TRANS_URL"
SU_LOGIN_URL="${SU_URL}site/log_in"
SU_GET_TALK_URL="${SU_URL}site/messages/get_talk/"
SU_COOKIE_JAR=${SU_MSGTOOLS_CFGDIR}/cookies.txt
SU_MSGTOOLS_WORKDIR=/run/user/${UID}/su-messaging-tools
SU_MSGTOOLS_LOGIN_HEADERS=${SU_MSGTOOLS_WORKDIR}/login.headers
SU_ADD_COOKIES="--cookie accept_rules=true"

usage() {
	echo $0 'login|talk-get conversation-id'
}

# Log in, obtain session cookie and save it to $SU_COOKIE_JAR.
su_login() {
	local SU_LOGIN_POST_DATA="--data-raw email=$SU_LOGIN -d password=$SU_PASS -d submitLogin=Zaloguj"

	curl -A "$UA" $SU_LOGIN_POST_DATA $SU_ADD_COOKIES -e $SU_LOGIN_URL -c $SU_COOKIE_JAR -D $SU_MSGTOOLS_LOGIN_HEADERS --silent -o /dev/null $SU_TRANS_LOGIN_URL

	if grep -q "^Location: $SU_TRANS_URL" $SU_MSGTOOLS_LOGIN_HEADERS ; then
		echo Login OK.
		rm $SU_MSGTOOLS_LOGIN_HEADERS
	else
		echo_stderr Login failed, investigate ${SU_MSGTOOLS_LOGIN_HEADERS}.
		exit 20
	fi
}

# Download recent messages in a conversation, for ID which was passed in a
# parameter.
su_talk_get() {
	local SU_CONVERSATION_ID=$1
	local TALKFILE=${SU_MSGTOOLS_WORKDIR}/${SU_CONVERSATION_ID}-$(date +%s)

	mkdir -p ${SU_MSGTOOLS_WORKDIR}

	curl -A "$UA" --silent $SU_ADD_COOKIES -b $SU_COOKIE_JAR -o $TALKFILE -D ${TALKFILE}.headers ${SU_GET_TALK_URL}${SU_CONVERSATION_ID}

	if grep -q "^Content-Type: application/json" ${TALKFILE}.headers ; then
		echo $TALKFILE
		rm ${TALKFILE}.headers
	else
		echo_stderr Downloading failed, investigate ${TALKFILE}.headers.
		exit 30
	fi

}

# Handle command line arguments to the script.
case "$1" in
	login)
		su_login
		;;
	talk-get)
		if [ -z "$2" ] ; then
			usage
			exit 5
		fi
		su_talk_get $2
		;;
	*)
		usage
		exit 5
		;;
esac

