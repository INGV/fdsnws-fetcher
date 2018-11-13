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
    echo "Processing node to create RESP: $( basename ${FDSNWS_NODE_PATH} )"

    # get 'STATIONXML_FULL_URL' from file
    STATIONXML_FULL_URL=$( cat ${FDSNWS_NODE_PATH}/stationxml_station.txt )

    # change 'level' to 'response'
    STATIONXML_FULL_URL="${STATIONXML_FULL_URL/level=station/level=response}"

    # change 'format' to 'xml'
    STATIONXML_FULL_URL="${STATIONXML_FULL_URL/format=text/format=xml}"

    # create RESP dir and set others
    DIR_DLESS_NODE=${FDSNWS_NODE_PATH}/dless
    DIR_LOG_NODE=${FDSNWS_NODE_PATH}/log
    DIR_RESP_NODE=${FDSNWS_NODE_PATH}/resp
    mkdir -p ${DIR_RESP_NODE}

    # get network and station
    while read NET_STA; do
        NETWORK=$( echo ${NET_STA} | awk -F"|" '{print $1}' )
        STATION=$( echo ${NET_STA} | awk -F"|" '{print $2}' )

        if [ -f ${DIR_DLESS_NODE}/${NETWORK}_${STATION}.dless ]; then
            echo " create RESP for \"${NETWORK}_${STATION}\" from \"${DIR_DLESS_NODE}/${NETWORK}_${STATION}.dless\""
            ${RDSEED} -f ${DIR_DLESS_NODE}/${NETWORK}_${STATION}.dless -q ${DIR_RESP_NODE} >> ${DIR_LOG_NODE}/rdseed__${NETWORK}_${STATION}.out 2>> ${DIR_LOG_NODE}/rdseed__${NETWORK}_${STATION}.err
            RET_RDSEED=${?}
            if (( ${RET_RDSEED} != 0 )); then
                cat ${DIR_LOG_NODE}/rdseed__${NETWORK}_${STATION}.err
                echo -e "\n"
            fi
        else
            echo "  the DLESS \"${DIR_DLESS_NODE}/${NETWORK}_${STATION}.dless\" doesn't exist"
        fi
    done < ${FDSNWS_NODE_PATH}/net_sta.txt
echo ""
done