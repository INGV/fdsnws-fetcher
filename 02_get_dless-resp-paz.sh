#!/bin/bash
#
#
# (c) 2024 Valentino Lauciani <valentino.lauciani@ingv.it>,
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
    echo "Retrieving station(s) info from: $( basename ${FDSNWS_NODE_PATH} )"

    # get 'STATIONXML_FULL_URL' from file
    STATIONXML_FULL_URL=$( cat ${FDSNWS_NODE_PATH}/stationxml_station.txt )

    # change 'level' to 'response'
    STATIONXML_FULL_URL="${STATIONXML_FULL_URL/level=station/level=response}"

    # change 'format' to 'xml'
    STATIONXML_FULL_URL="${STATIONXML_FULL_URL/format=text/format=xml}"

    # create TYPE dir
    if [[ "${TYPE}" == "stationxml" ]]; then
        DIR_TYPE_NODE=${FDSNWS_NODE_PATH}/stationxml
    else
        DIR_TYPE_NODE=${FDSNWS_NODE_PATH}/dless
    fi
    DIR_LOG_NODE=${DIR_TYPE_NODE}/log
    mkdir -p ${DIR_TYPE_NODE}
    mkdir -p ${DIR_LOG_NODE}

    # get network and station
    N_NET_STA=$( wc ${FDSNWS_NODE_PATH}/net_sta.txt | awk '{print $1}' )
    COUNT=1
    while read NET_STA; do
	echo "${COUNT}/${N_NET_STA} - Processing \"${NET_STA}\" on \"$( basename ${FDSNWS_NODE_PATH} )\"" > /dev/null

        NETWORK=$( echo ${NET_STA} | awk -F"|" '{print $1}' )
        STATION=$( echo ${NET_STA} | awk -F"|" '{print $2}' )
        STATIONXML_FOR_TYPE=

        # build URL to get StationXML
        # START - Soluzione 1
        #STATIONXML_FULL_URL__NET__FIRST=$( echo ${STATIONXML_FULL_URL} | awk -F"network=" '{print $1}' )
        #STATIONXML_FULL_URL__NET__SECOND=$( echo ${STATIONXML_FULL_URL} | awk -F"network=" '{print $2}' | sed 's/^[^&]*//' )
        #STATIONXML_FOR_TYPE="${STATIONXML_FULL_URL__NET__FIRST}network=${NETWORK}${STATIONXML_FULL_URL__NET__SECOND}"

        #STATIONXML_FOR_TYPE__STA__FIRST=$( echo ${STATIONXML_FOR_TYPE} | awk -F"station=" '{print $1}' )
        #STATIONXML_FOR_TYPE__STA__SECOND=$( echo ${STATIONXML_FOR_TYPE} | awk -F"station=" '{print $2}' | sed 's/^[^&]*//' )
        #STATIONXML_FOR_TYPE="${STATIONXML_FOR_TYPE__STA__FIRST}station=${STATION}${STATIONXML_FOR_TYPE__STA__SECOND}"
        # END - Soluzione 1
        # START - Soluzione 2
        STATIONXML_FOR_TYPE=$( echo ${STATIONXML_FULL_URL} | sed -e "s/network=[^&]\+//" | sed -e "s/station=[^&]\+//" | sed -e "s/net=[^&]\+//" | sed -e "s/sta=[^&]\+//" )"&network=${NETWORK}&station=${STATION}"
        STATIONXML_FOR_TYPE=$( echo ${STATIONXML_FOR_TYPE} | sed -e "s/\&\&\&/\&/" | sed -e "s/\&\&/\&/" )
        # END - Soluzione 2
        

        # Running process
        timeout -k 5 2m ${DIR_WORK}/021_get_dless-resp-paz_parallel.sh -k "${COUNT}/${N_NET_STA}" -o ${DIR_TYPE_NODE}/${NETWORK}_${STATION}.type -u "${STATIONXML_FOR_TYPE}" -t ${TYPE} &

        # Checking process number
        RUNNING_PROCESS=$( ps axu | grep "021_get_dless-resp-paz_parallel.sh" | grep -v "grep" | wc | awk '{print $1}' )
        while (( ${RUNNING_PROCESS} > ${N_PROCESS_TO_GET_TYPE} )); do
            echo "****** there are just \"${RUNNING_PROCESS}\" parallel process running (the limit is \"${N_PROCESS_TO_GET_TYPE}\"), waiting... ******"
            sleep 10
            RUNNING_PROCESS=$( ps axu | grep "021_get_dless-resp-paz_parallel.sh" | grep -v "grep" | wc | awk '{print $1}' )
        done
	COUNT=$(( ${COUNT} + 1 ))
    done < ${FDSNWS_NODE_PATH}/net_sta.txt
done
wait
echo ""
