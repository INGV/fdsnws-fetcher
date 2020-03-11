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

# Check DIR_TMP
if [ ! -d ${DIR_TMP} ]; then
        echo ""
        echo " DIR_TMP doesn't exists."
        echo ""
        exit 1
fi

### START - Check parameters ###
TYPE=
while getopts :o:d:u:t: OPTION
do
	case ${OPTION} in
        o)	FILE_OUTPUT_MSEED="${OPTARG}"
			;;
        d)	FILE_OUTPUT_DLESS="${OPTARG}"
			;;
        t)	TYPE="${OPTARG}"
			;;
        u)	DATASELECT_URL="${OPTARG}"
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
BASENAME_MSEED=$( basename ${FILE_OUTPUT_MSEED} )
DIRNAME_MSEED=$( dirname ${FILE_OUTPUT_MSEED} )
DIR_NODE=$( cd ${DIRNAME_MSEED} && cd ../ && pwd )
DIR_MSEED_LOG=${DIRNAME_MSEED}/log
FILE_OUTPUT_MSEED_HTTPCODE_LOG=${DIR_MSEED_LOG}/$( basename ${FILE_OUTPUT_MSEED} ).httpcode

# create dir
if [ ! -d ${DIR_MSEED_LOG} ]; then
    mkdir -p ${DIR_MSEED_LOG}
fi

# running process
COUNT=0
HTTP_CODE=429
while (( ${HTTP_CODE} == 429 )) && (( ${COUNT} < 5 )); do
        curl --digest "${DATASELECT_URL}" -o "${FILE_OUTPUT_MSEED}" --write-out "%{http_code}\\n" > ${FILE_OUTPUT_MSEED_HTTPCODE_LOG} -s
        RET_CODE=$?
        HTTP_CODE=$( cat ${FILE_OUTPUT_MSEED_HTTPCODE_LOG} )
        if (( ${HTTP_CODE} == 429 )); then
                echo "TOO MANY REQUEST - requesting \"${DATASELECT_URL}\". RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}. I'll try later..."
                sleep 5
        fi
        COUNT=$(( ${COUNT} + 1 ))
done
if (( ${RET_CODE} == 0 )); then
    if (( ${HTTP_CODE} == 200 )); then
        if [ -f ${FILE_OUTPUT_MSEED} ]; then
            echo "OK - file ${FILE_OUTPUT_MSEED} successfully downloaded."
            if [[ "${TYPE}" == "sac" ]]; then
                # create SAC dir
                DIR_SAC_NODE=${DIR_NODE}/sac
                if [ ! -d ${DIR_SAC_NODE} ]; then
                    mkdir -p ${DIR_SAC_NODE}
                fi
		# Convert to SAC.
		python /opt/seed_handler.py --oud ${DIR_SAC_NODE} --fmtout SAC --filein ${FILE_OUTPUT_MSEED}

                RET=$?
                if [ $RET -ne 0 ]; then
                    echo " ERROR - converting ${FILE_OUTPUT_MSEED} to SAC format."
                fi
            fi
        else
            echo " ERROR - skip conversion. File ${FILE_OUTPUT_DLESS} not found."
        fi
    elif (( ${HTTP_CODE} == 204 )); then
        echo "NODATA - requesting \"${DATASELECT_URL}\". RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}"
        if [ -f ${FILE_OUTPUT_MSEED} ]; then
            mv ${FILE_OUTPUT_MSEED} ${DIR_MSEED_LOG}/$( basename ${FILE_OUTPUT_MSEED} ).log
            echo "NODATA" >> ${DIR_MSEED_LOG}/$( basename ${FILE_OUTPUT_MSEED} ).log
            echo "REQUEST: ${DATASELECT_URL}" >> ${DIR_MSEED_LOG}/$( basename ${FILE_OUTPUT_MSEED} ).log
            echo "RET_CODE: ${RET_CODE}" >> ${DIR_MSEED_LOG}/$( basename ${FILE_OUTPUT_MSEED} ).log
            echo "HTTP_CODE: ${HTTP_CODE}" >> ${DIR_MSEED_LOG}/$( basename ${FILE_OUTPUT_MSEED} ).log
        fi
    elif (( ${HTTP_CODE} == 403 )); then
        echo "FORBIDDEN - requesting \"${DATASELECT_URL}\". RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}"
        if [ -f ${FILE_OUTPUT_MSEED} ]; then
            mv ${FILE_OUTPUT_MSEED} ${DIR_MSEED_LOG}/$( basename ${FILE_OUTPUT_MSEED} ).log
        fi
    elif (( ${HTTP_CODE} == 429 )); then
        echo "TOO MANY REQUEST - requesting \"${DATASELECT_URL}\". RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}"
        echo ${DATASELECT_URL} > ${DIR_MSEED_LOG}/$( basename ${FILE_OUTPUT_MSEED} ).tooManyRequest
    else
        echo "UNKNOWN - requesting \"${DATASELECT_URL}\". RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}"
    fi
else
    echo "ERROR - requesting \"${DATASELECT_URL}\". RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}"
    if [ -f ${FILE_OUTPUT_MSEED} ]; then
        mv ${FILE_OUTPUT_MSEED} ${DIR_MSEED_LOG}/$( basename ${FILE_OUTPUT_MSEED} ).log
    fi
fi

#
if [ -f ${FILE_OUTPUT_MSEED_HTTPCODE_LOG} ]; then
    rm -f ${FILE_OUTPUT_MSEED_HTTPCODE_LOG}
fi
