#!/bin/bash
#

#
# xml2seed.sh
#
# This script helps staging of station response metadata to a local storage.
# It uses an FDSN station service to download station metadata in StationXML
# and converts them in the desired format, here RESP files.
#
# (c) 2017 Peter Danecek <peter.danecek@ingv.it>,
#          Valentino Lauciani <valentino.lauciani@ingv.it>,
#          Matteo Quintiliani <matteo.quintiliani@ingv.it>,
#          Istituto Nazione di Geofisica e Vulcanologia.
# 
#####################################################3

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
    echo "Processing node to create DLESS: $( basename ${FDSNWS_NODE_PATH} )"

    # get 'STATIONXML_FULL_URL' from file
    STATIONXML_FULL_URL=$( cat ${FDSNWS_NODE_PATH}/stationxml_station.txt )

    # change 'level' to 'response'
    STATIONXML_FULL_URL="${STATIONXML_FULL_URL/level=station/level=response}"

    # change 'format' to 'xml'
    STATIONXML_FULL_URL="${STATIONXML_FULL_URL/format=text/format=xml}"

    # create DLESS dir
    DIR_DLESS_NODE=${FDSNWS_NODE_PATH}/dless
    DIR_LOG_NODE=${DIR_DLESS_NODE}/log
    mkdir -p ${DIR_DLESS_NODE}
    mkdir -p ${DIR_LOG_NODE}

    # get network and station
    while read NET_STA; do
        NETWORK=$( echo ${NET_STA} | awk -F"|" '{print $1}' )
        STATION=$( echo ${NET_STA} | awk -F"|" '{print $2}' )
        STATIONXML_FOR_DLESS=

        # build URL to get StationXML
        # START - Soluzione 1
        #STATIONXML_FULL_URL__NET__FIRST=$( echo ${STATIONXML_FULL_URL} | awk -F"network=" '{print $1}' )
        #STATIONXML_FULL_URL__NET__SECOND=$( echo ${STATIONXML_FULL_URL} | awk -F"network=" '{print $2}' | sed 's/^[^&]*//' )
        #STATIONXML_FOR_DLESS="${STATIONXML_FULL_URL__NET__FIRST}network=${NETWORK}${STATIONXML_FULL_URL__NET__SECOND}"

        #STATIONXML_FOR_DLESS__STA__FIRST=$( echo ${STATIONXML_FOR_DLESS} | awk -F"station=" '{print $1}' )
        #STATIONXML_FOR_DLESS__STA__SECOND=$( echo ${STATIONXML_FOR_DLESS} | awk -F"station=" '{print $2}' | sed 's/^[^&]*//' )
        #STATIONXML_FOR_DLESS="${STATIONXML_FOR_DLESS__STA__FIRST}station=${STATION}${STATIONXML_FOR_DLESS__STA__SECOND}"
        # END - Soluzione 1
        # START - Soluzione 2
        STATIONXML_FOR_DLESS=$( echo ${STATIONXML_FULL_URL} | sed -e "s/network=[^&]\+//" | sed -e "s/station=[^&]\+//" )"&network=${NETWORK}&station=${STATION}"
        # END - Soluzione 2
        #
#        echo " create DLESS for \"${NETWORK}_${STATION}\" from \"${STATIONXML_FOR_DLESS}\""

        # Checking process number
        RUNNING_PROCESS=$( ps axu | grep "021_get_dless-resp-parallel.sh" | grep -v "grep" | wc | awk '{print $1}' )
        while (( ${RUNNING_PROCESS} > ${N_PROCESS_TO_GET_DLESS} )); do
            echo " !!! there are just \"${RUNNING_PROCESS}\" parallel process (the limit is \"${N_PROCESS_TO_GET_DLESS}\") running, waiting..."
            sleep 10
            RUNNING_PROCESS=$( ps axu | grep "021_get_dless-resp-parallel.sh" | grep -v "grep" | wc | awk '{print $1}' )
        done
        ${DIR_WORK}/021_get_dless-resp-parallel.sh -o ${DIR_DLESS_NODE}/${NETWORK}_${STATION}.dless -u "${STATIONXML_FOR_DLESS}" -t ${TYPE} &
        sleep 1

#        ${STATIONXML_TO_SEED} -o ${DIR_DLESS_NODE}/${NETWORK}_${STATION}.dless "${STATIONXML_FOR_DLESS}" >> ${DIR_LOG_NODE}/stationxml-converter__${NETWORK}_${STATION}.out 2>> ${DIR_LOG_NODE}/stationxml-converter__${NETWORK}_${STATION}.err
#        RET_STATIONXML_TO_SEED=${?}
#        if (( ${RET_STATIONXML_TO_SEED} != 0 )); then
#            cat ${DIR_LOG_NODE}/stationxml-converter__${NETWORK}_${STATION}.err
#            echo -e "\n"
#        fi

        #
#        if [[ "${TYPE}" == "resp" ]]; then
#            if [ -f ${DIR_DLESS_NODE}/${NETWORK}_${STATION}.dless ]; then
#                DIR_RESP_NODE=${FDSNWS_NODE_PATH}/resp
#                if [ ! -d ${DIR_RESP_NODE} ]; then
#                    mkdir -p ${DIR_RESP_NODE}
#                fi
#                echo " create RESP for \"${NETWORK}_${STATION}\" from \"${DIR_DLESS_NODE}/${NETWORK}_${STATION}.dless\""
#                ${RDSEED} -f ${DIR_DLESS_NODE}/${NETWORK}_${STATION}.dless -q ${DIR_RESP_NODE} >> ${DIR_LOG_NODE}/rdseed__${NETWORK}_${STATION}.out 2>> ${DIR_LOG_NODE}/rdseed__${NETWORK}_${STATION}.err
#                RET_RDSEED=${?}
#                if (( ${RET_RDSEED} != 0 )); then
#                    cat ${DIR_LOG_NODE}/rdseed__${NETWORK}_${STATION}.err
#                    echo -e "\n"
#                fi
#            else
#                echo "  the DLESS \"${DIR_DLESS_NODE}/${NETWORK}_${STATION}.dless\" doesn't exist"
#            fi
#        fi
    done < ${FDSNWS_NODE_PATH}/net_sta.txt
done
#echo ""
#echo "waiting, retring data..."
wait
echo ""