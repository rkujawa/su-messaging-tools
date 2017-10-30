#!/bin/bash
. $(dirname $0)/su-conversation.subr

# Count the number of messages in an array. Currently very naive.
conversation_array_length() {
	CONV_ARRAY_LEN=$(jq 'length' $1)
}

conversation_message_get_last() {
	conversation_array_length $1
	LASTMSG=$(jq ".[$((CONV_ARRAY_LEN-1))]" $1)
	echo $LASTMSG
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
messages_dump_process() {
	conversation_log_path_prep

	CONVERSATION_LOGFILE=${SU_MSGTOOLS_CONVLOG_DIR}/${CONV_ID}

	if [ ! -f ${SU_MSGTOOLS_CONVLOG_DIR}/${CONV_ID} ] ; then
		echo_stderr Conversation log empty, populating from current dump. 

		conversation_log_populate_from_dump
	else
		conversation_message_get_last $CONVERSATION_LOGFILE
	fi	
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
	DUMP_FILE=$(${SU_MSGTOOL_DUMP} talk-get ${1})
#	echo ${SU_MSGTOOL_DUMP} talk-get ${1}
}

messages_dump_remove() {
	rm -v $DUMP_FILE
}

CONV_ID=$1

messages_dump_get ${CONV_ID} 
echo $DUMP_FILE
messages_dump_process ${DUMP_FILE}

#messages_dump_remove ${DUMP_FILE}

