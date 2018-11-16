#!/bin/bash
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
while getopts :t: OPTION
do
	case ${OPTION} in
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

#
for FDSNWS_NODE_PATH in $( ls -d ${DIR_TMP}/* ); do
    echo "Processing node to create DATASELECT_LIST: $( basename ${FDSNWS_NODE_PATH} )"

    # get 'STATIONXML_FULL_URL' from file
    STATIONXML_FULL_URL=$( cat ${FDSNWS_NODE_PATH}/stationxml_station.txt )

    # change 'level' from 'station' to 'channel'
    STATIONXML_FULL_URL_CHANNEL=$( echo ${STATIONXML_FULL_URL} | sed 's/level=station/level=channel/' )

    # send request
    curl "${STATIONXML_FULL_URL_CHANNEL}" -o "${FILE_CURL1}" --write-out "%{http_code}\\n" > ${FILE_CURL1_HTTPCODE} -s
    RETURNED_CODE=${?}

    HTTP_CODE=$( cat ${FILE_CURL1_HTTPCODE} )
    if (( ${RETURNED_CODE} == 0 )) && (( ${HTTP_CODE} == 200 )); then
        # Remove comment line from StationXML 'text' output
        grep -v ^# ${FILE_CURL1} > ${FILE_CURL1}.new
        mv ${FILE_CURL1}.new ${FILE_CURL1}

        # Get only NETWORK, STATION, LOCATION and CHANNEL, Sort and Unique
        cat ${FILE_CURL1} | awk -F"|" '{print $1"|"$2"|"$3"|"$4}' | sort -u > ${FILE_CURL1}.new
        mv ${FILE_CURL1}.new ${FDSNWS_NODE_PATH}/stationxml_channel.txt
    fi

    # START - Parse URL params
    STARTTIME="$( date +%Y-%m-%d )T00:00:00"
    ENDTIME="$( date +%Y-%m-%d )T23:59:59"

    set -f   # disable wildcard expansion
    ARRAY_URL_TMP=(${DATASELECT_PARAMS//[=&]/ })
    set +f   # restore wildcard expansion

    for ((i=0; i<${#ARRAY_URL_TMP[@]}; i+=2))
    do
        if [[ "${ARRAY_URL_TMP[i]}" == "start" ]] || [[ "${ARRAY_URL_TMP[i]}" == "starttime" ]]; then
            STARTTIME="${ARRAY_URL_TMP[i+1]}"
        elif [[ "${ARRAY_URL_TMP[i]}" == "end" ]] || [[ "${ARRAY_URL_TMP[i]}" == "endtime" ]]; then
            ENDTIME="${ARRAY_URL_TMP[i+1]}"
        fi
    done
    # END - Parse URL params

    # create 'dataselect_list' dir
    DIR_DATASELECT_LIST_NODE=${FDSNWS_NODE_PATH}/dataselect_list
    mkdir -p ${DIR_DATASELECT_LIST_NODE}

    # build base 'dataselect' URL
    DATASELECT_BASE_URL=$( echo ${STATIONXML_FULL_URL} | awk -F"?" '{print $1}' | sed 's/station/dataselect/' )

    # get network and station
    while read NET_STA_LOC_CHA; do
        NETWORK=$( echo ${NET_STA_LOC_CHA} | awk -F"|" '{print $1}' )
        STATION=$( echo ${NET_STA_LOC_CHA} | awk -F"|" '{print $2}' )
        LOCATION=$( echo ${NET_STA_LOC_CHA} | awk -F"|" '{print $3}' )
        CHANNEL=$( echo ${NET_STA_LOC_CHA} | awk -F"|" '{print $4}' )

        if [ -z "${LOCATION}" ]; then
            LOC_OPTIONAL=""
        else
            LOC_OPTIONAL="&location=${LOCATION}"
        fi

        # build DATASELCT URL
        DATASELECT_URL="${DATASELECT_BASE_URL}?network=${NETWORK}&station=${STATION}&channel=${CHANNEL}${LOC_OPTIONAL}&starttime=${STARTTIME}&endtime=${ENDTIME}"
        echo "${DATASELECT_URL}" >> ${DIR_DATASELECT_LIST_NODE}/dataselect_urls.txt

        if [[ "${TYPE}" == "miniseed" ]] || [[ "${TYPE}" == "sac" ]] || [[ "${TYPE}" == "fullseed" ]]; then
            # create MSEED dir
            DIR_MSEED_NODE=${FDSNWS_NODE_PATH}/miniseed
            if [ ! -d ${DIR_MSEED_NODE} ]; then
                mkdir -p ${DIR_MSEED_NODE}
            fi

            #
            FILE_OUTPUT_MSEED="${DIR_MSEED_NODE}/${NETWORK}.${STATION}.${LOCATION}.${CHANNEL}.miniseed"
            FILE_OUTPUT_DLESS="${FDSNWS_NODE_PATH}/dless/${NETWORK}_${STATION}.dless"
            
            # Running process
            ${DIR_WORK}/031_get_mseed-sac_parallel.sh -o ${FILE_OUTPUT_MSEED} -d ${FILE_OUTPUT_DLESS} -u ${DATASELECT_URL} -t ${TYPE} &

            # Checking process number
            RUNNING_PROCESS=$( ps axu | grep "031_get_mseed-sac_parallel.sh" | grep -v "grep" | wc | awk '{print $1}' )
            while (( ${RUNNING_PROCESS} > ${N_PROCESS_TO_GET_DLESS} )); do
                echo " !!! there are just \"${RUNNING_PROCESS}\" parallel process running (the limit is \"${N_PROCESS_TO_GET_DLESS}\"), waiting..."
                sleep 5
                RUNNING_PROCESS=$( ps axu | grep "031_get_mseed-sac_parallel.sh" | grep -v "grep" | wc | awk '{print $1}' )
            done
        fi
    done < ${FDSNWS_NODE_PATH}/stationxml_channel.txt
done
wait
echo ""