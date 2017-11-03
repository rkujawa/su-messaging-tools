#!/bin/bash
. $(dirname $0)/su-conversation.subr

MYDIR=$(dirname $0)
#SU_MSG_VERBOSE=yes

# Count the number of messages in an array. Currently very naive.
conversation_array_length() {
	CONV_ARRAY_LEN=$(jq 'length' $1)
}

conversation_message_get_last() {
	conversation_array_length $1
	LASTMSG=$(jq ".[$((CONV_ARRAY_LEN-1))]" $1)
}

conversation_log_path_prep() {
	if [ ! -d ${SU_MSGTOOLS_CONVLOG_DIR} ] ; then
		mkdir -p ${SU_MSGTOOLS_CONVLOG_DIR}
	fi

	if [ ! -d ${SU_MSGTOOLS_CONVLOG_DIR} ] ; then
		echo_stderr Cannot create converation log dir.
		exit 10
	fi
}

# Create a new conversation log file, copying messages from dump. JSON
# array from dump needs to be reversed since it contains messages in order
# from newest to oldest (unlike typical log).
conversation_log_populate_from_dump() {
	jq 'reverse' ${DUMP_FILE} > ${CONVERSATION_LOGFILE}
}

# Process the dump, extract new messages and append them to log file.
#
# Try to be smart about it. Or at least not completely dumb.
messages_dump_process() {
	conversation_log_path_prep

	CONVERSATION_LOGFILE=${SU_MSGTOOLS_CONVLOG_DIR}/${CONV_ID}

	if [ ! -f ${SU_MSGTOOLS_CONVLOG_DIR}/${CONV_ID} ] ; then
		echo_stderr Conversation log empty, populating from current dump. 

		conversation_log_populate_from_dump
	else
		conversation_message_get_last $CONVERSATION_LOGFILE

		if [ "$SU_MSG_VERBOSE" == "yes" ] ; then
			echo_stderr Last logged message: $LASTMSG
		fi

		messages_dump_check_fresh $DUMP_FILE

		if [ $? -eq 1 ] ; then
			echo_stderr Log file does not contain any messages from dump, possibly some messages were lost.
		fi

		if [ $LASTFRESHIDX -eq 0 ] ; then

			if [ "$SU_MSG_VERBOSE" == "yes" ] ; then
				echo_stderr No new messages.
			fi
			return
		fi
		echo_stderr Messages up to $LASTFRESHIDX are fresh. Copying to log.
		messages_dump_extract_fresh $LASTFRESHIDX

		if [ ! -z ${SU_NOTIFY_HOOK+x} ] ; then
			export DUMP_NEWMSGS CONV_ID LASTFRESHIDX
			$SU_NOTIFY_HOOK
		fi

		messages_dump_fresh_conversation_log
	fi	
}

# Extract messages from dump, reverse array order, save to temporary file.
messages_dump_extract_fresh() {
	DUMP_NEWMSGS=${DUMP_FILE}.fresh	
	jq ".[0:${LASTFRESHIDX}]|reverse" $DUMP_FILE > $DUMP_NEWMSGS
}

messages_dump_fresh_conversation_log() {
	local CONVERSATION_LOGFILE_TMP=${CONVERSATION_LOGFILE}.tmp
	jq -s add $CONVERSATION_LOGFILE $DUMP_NEWMSGS > $CONVERSATION_LOGFILE_TMP
	if [ -f $CONVERSATION_LOGFILE_TMP ] ; then
		mv ${SU_MSG_VERBOSE+"-v"} $CONVERSATION_LOGFILE_TMP $CONVERSATION_LOGFILE
	else
		echo_stderr Failed to add messages from dump to log.
	fi
}

# Check which messages in the dump are fresh (i.e. do not appear in our
# local log file). Get the index of last fresh message, so that we can
# safely copy the array.
messages_dump_check_fresh() {

	local i=0

	conversation_array_length $DUMP_FILE 
	DUMP_LEN=$CONV_ARRAY_LEN

	while [ $i -lt $DUMP_LEN ] ; do
		CURMSG=$(jq ".[${i}]" $DUMP_FILE)
		LASTFRESHIDX=$i
		if [ "$CURMSG" == "$LASTMSG" ] ; then
			return 0
		fi

		i=$((i+1))
	done

	return 1
}

message_json_to_var() {

	JSONFILTER_MSG_TO_VARS='|to_entries[]|(.key+"=\""+.value+"\"")'
	eval $(jq -r ".[${1}]"${JSONFILTER_MSG_TO_VARS} ${DUMP_FILE})
	echo $msg
	echo $uid
	echo $date
	echo $conversation_id

}

#message_display() {
#}

messages_dump_get() {
	if [ "$SU_MSG_VERBOSE" == "yes" ] ; then
		echo running: ${SU_MSGTOOL_DUMP} talk-get ${1}
	fi
	DUMP_FILE=$(${MYDIR}/${SU_MSGTOOL_DUMP} talk-get ${1})
}

messages_dump_remove() {
	if [ ! -z "${DUMP_FILE}" ] ; then
		rm ${SU_MSG_VERBOSE+"-v"} ${DUMP_FILE}*
	fi
}

# XXX: add lock for conversation log

CONV_ID=$1

messages_dump_get ${CONV_ID} 
#echo $DUMP_FILE
messages_dump_process ${DUMP_FILE}

messages_dump_remove ${DUMP_FILE}

