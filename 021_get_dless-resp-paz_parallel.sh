#!/bin/bash
#
#
# (c) 2018 Valentino Lauciani <valentino.lauciani@ingv.it>,
#          Matteo Quintiliani <matteo.quintiliani@ingv.it>,
#          Istituto Nazione di Geofisica e Vulcanologia.
# 
#####################################################

# Import config file
. $(dirname $0)/config.sh

### START - Check parameters ###
TYPE=
INPUT_STRING=
while getopts :o:k:u:t: OPTION
do
	case ${OPTION} in
        o)	FILE_OUTPUT_TYPE="${OPTARG}"
		;;
        u)	STATIONXML_INPUT_URL="${OPTARG}"
		;;
        k)      INPUT_STRING="${OPTARG}"
                ;;
        t)	TYPE="${OPTARG}"
		;;
        \?) echo "Invalid option: -$OPTARG" >/dev/null
		shift
		;;
        *)  #echo $OPTARG >/dev/null
		echo "Invalid OPTARG: -$OPTARG" >&2
                ;;
	esac
done
### END - Check parameters ###

# Set var
BASENAME_TYPE=$( basename ${FILE_OUTPUT_TYPE} )
DIRNAME_TYPE=$( dirname ${FILE_OUTPUT_TYPE} )
DIR_NODE=$( cd ${DIRNAME_TYPE} && cd ../ && pwd )
DIR_TYPE_LOG_NODE=${DIRNAME_TYPE}/log

# create dir
if [ ! -d ${DIR_TYPE_LOG_NODE} ]; then
    mkdir -p ${DIR_TYPE_LOG_NODE}
fi

echo "${INPUT_STRING} - Get \"$( echo ${BASENAME_TYPE} | sed 's|.type||' )\" StationXML: \"${STATIONXML_INPUT_URL}\""
if [[ -f ${FILE_OUTPUT_TYPE} ]]; then
	echo " TYPE already exists"
else	
	COUNT=1
	COUNT_LIMIT=5
	HTTP_CODE=429
	RET_CODE=-9
	PREV=0
        FILE_OUTPUT_TYPE_STATIONXML=$( echo ${FILE_OUTPUT_TYPE} | sed 's|\.type|\.stationxml|' )
	while ( (( ${HTTP_CODE} == 429 )) || (( ${HTTP_CODE} == 503 )) ) && (( ${COUNT} <= ${COUNT_LIMIT} )); do
        	curl --digest "${STATIONXML_INPUT_URL}" -o "${FILE_OUTPUT_TYPE_STATIONXML}" --write-out "%{http_code}\\n" > ${DIR_TYPE_LOG_NODE}/${BASENAME_TYPE}.stationxml-converter.httpcode -s
	        RET_CODE=$?
        	HTTP_CODE=$( cat ${DIR_TYPE_LOG_NODE}/${BASENAME_TYPE}.stationxml-converter.httpcode )
        	if (( ${HTTP_CODE} == 429 )); then
                	echo "TOO MANY REQUEST (for ${INPUT_STRING}) - retrieving \"${STATIONXML_INPUT_URL}\". RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}. Tentative: ${COUNT}/${COUNT_LIMIT}"
                	sleep 5
			PREV=1
		elif (( ${HTTP_CODE} == 503 )); then
			echo "SERVICE UNAVAILABLE (for ${INPUT_STRING}) - retrieving \"${STATIONXML_INPUT_URL}\". RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}. Tentative: ${COUNT}/${COUNT_LIMIT}"
			sleep 5
			PREV=1
                elif (( ${PREV} == 1 )); then
			echo " DONE (for ${INPUT_STRING}) - retrieving \"${STATIONXML_INPUT_URL}\". RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}. Tentative: ${COUNT}/${COUNT_LIMIT}"
        	fi
        	COUNT=$(( ${COUNT} + 1 ))
	done
	if [ -f ${DIR_TYPE_LOG_NODE}/${BASENAME_TYPE}.stationxml-converter.httpcode ]; then
    		rm -f ${DIR_TYPE_LOG_NODE}/${BASENAME_TYPE}.stationxml-converter.httpcode
	fi

	if (( ${RET_CODE} == 0 )); then
		if (( ${HTTP_CODE} == 200 )); then
			if [ -f ${FILE_OUTPUT_TYPE_STATIONXML} ]; then
				echo " OK (for ${INPUT_STRING}) - file \"${FILE_OUTPUT_TYPE_STATIONXML}\" successfully downloaded." > /dev/null
                                if [[ "${TYPE}" == "stationxml" ]]; then
                                    echo "" >/dev/null
                                else
                                    FILE_OUTPUT_TYPE_DLESS=$( echo ${FILE_OUTPUT_TYPE} | sed 's|\.type|\.dless|' )
				    ${STATIONXML_TO_SEED} --input ${FILE_OUTPUT_TYPE_STATIONXML} --output ${FILE_OUTPUT_TYPE_DLESS}
				    RET_CODE=$?
				    if (( ${RET_CODE} == 0 )); then
                                        echo "  OK (for ${INPUT_STRING}) - converting StationXML to TYPE" > /dev/null
                                    else
                                        echo "  ERROR (for ${INPUT_STRING}) - converting StationXML to TYPE"
                                    fi
				    rm ${FILE_OUTPUT_TYPE_STATIONXML}
                                fi
			else
				echo " ERROR (for ${INPUT_STRING}) - the file \"${FILE_OUTPUT_TYPE_STATIONXML}\" doesn't exist."
			fi
		elif (( ${HTTP_CODE} == 204 )); then
			echo " NODATA (for ${INPUT_STRING}) - retrieving \"${STATIONXML_INPUT_URL}\". RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}"
		elif (( ${HTTP_CODE} == 403 )); then
			echo " FORBIDDEN (for ${INPUT_STRING}) - retrieving \"${STATIONXML_INPUT_URL}\". RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}"
		elif (( ${HTTP_CODE} == 429 )); then
			#echo " TOO MANY REQUEST (for ${INPUT_STRING}) - retrieving \"${STATIONXML_INPUT_URL}\". RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}"
			echo "" > /dev/null
                elif (( ${HTTP_CODE} == 503 )); then
                        #echo " SERVICE UNAVAILABLE (for ${INPUT_STRING}) - retrieving \"${STATIONXML_INPUT_URL}\". RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}"
			echo "" > /dev/null
    		else
        		echo " UNKNOWN (for ${INPUT_STRING}) - retrieving \"${STATIONXML_INPUT_URL}\". RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}"
		fi
	else
    		echo " ERROR (for ${INPUT_STRING}) - retrieving \"${STATIONXML_INPUT_URL}\". RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}"
	fi


	#${STATIONXML_TO_SEED} -o ${FILE_OUTPUT_TYPE} "${STATIONXML_INPUT_URL}" >> ${DIR_TYPE_LOG_NODE}/${BASENAME_TYPE}.stationxml-converter.out 2>> ${DIR_TYPE_LOG_NODE}/${BASENAME_TYPE}.stationxml-converter.err
	#RET_STATIONXML_TO_SEED=${?}
	#if (( ${RET_STATIONXML_TO_SEED} != 0 )); then
    	#	echo "  ERROR - Retriving StationXML from \"${STATIONXML_INPUT_URL}\". Check: ${DIR_TYPE_LOG_NODE}/${BASENAME_TYPE}.stationxml-converter.err"
    	#	echo ""
	#fi
fi

# Create RESP and/or PAZ
if [ -s ${FILE_OUTPUT_TYPE_DLESS} ]; then
    if [[ "${TYPE}" == "resp" ]]; then
        DIR_RESP_NODE=${DIR_NODE}/resp
        if [ ! -d ${DIR_RESP_NODE} ]; then
            mkdir -p ${DIR_RESP_NODE}
        fi
        DIR_RESP_NODE_TMP=${DIR_NODE}/resp/${BASENAME_TYPE}
        if [ ! -d ${DIR_RESP_NODE_TMP} ]; then
            mkdir -p ${DIR_RESP_NODE_TMP}
        fi
        DIR_RESP_LOG_NODE=${DIR_RESP_NODE}/log
        if [ ! -d ${DIR_RESP_LOG_NODE} ]; then
            mkdir -p ${DIR_RESP_LOG_NODE}
        fi

        echo " OK (for ${INPUT_STRING}) - create RESP from \"${FILE_OUTPUT_TYPE_DLESS}\""
        ${RDSEED} -R -S -f ${FILE_OUTPUT_TYPE_DLESS} -q ${DIR_RESP_NODE_TMP} >> ${DIR_RESP_LOG_NODE}/${BASENAME_TYPE}.rdseed.out 2>> ${DIR_RESP_LOG_NODE}/${BASENAME_TYPE}.rdseed.err
        RET_RDSEED=${?}
        if (( ${RET_RDSEED} != 0 )); then
            cat ${DIR_RESP_LOG_NODE}/${BASENAME_TYPE}.rdseed.err
            echo -e "\n"
        fi
        if [ -f ${DIR_RESP_NODE_TMP}/rdseed.stations ]; then
            cat ${DIR_RESP_NODE_TMP}/rdseed.stations >> ${DIR_RESP_NODE}/rdseed.stations.info
            rm ${DIR_RESP_NODE_TMP}/rdseed.stations
        fi
	for FILE_RESP in $( find ${DIR_RESP_NODE_TMP} -name RESP.??.* ); do 
            mv ${FILE_RESP} ${DIR_RESP_NODE}; 
	done
	rm -fr ${DIR_RESP_NODE_TMP}
    fi
    if [[ "${TYPE}" == "paz" ]]; then
        DIR_PAZ_NODE=${DIR_NODE}/paz
        if [ ! -d ${DIR_PAZ_NODE} ]; then
            mkdir -p ${DIR_PAZ_NODE}
        fi
        DIR_PAZ_LOG_NODE=${DIR_PAZ_NODE}/log
        if [ ! -d ${DIR_PAZ_LOG_NODE} ]; then
            mkdir -p ${DIR_PAZ_LOG_NODE}
        fi
        echo " OK (for ${INPUT_STRING}) - create PAZ from \"${FILE_OUTPUT_TYPE_DLESS}\""
        ${RDSEED} -p -f ${FILE_OUTPUT_TYPE_DLESS} -q ${DIR_PAZ_NODE} >> ${DIR_PAZ_LOG_NODE}/${BASENAME_TYPE}.rdseed.out 2>> ${DIR_PAZ_LOG_NODE}/${BASENAME_TYPE}.rdseed.err
        RET_RDSEED=${?}
        if (( ${RET_RDSEED} != 0 )); then
            cat ${DIR_PAZ_LOG_NODE}/${BASENAME_TYPE}.rdseed.err
            echo -e "\n"
        fi
    fi
fi

