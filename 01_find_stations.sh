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

# Functions
function usage_entrypoint() {
BASE_COMMAND="docker run -it --rm -v \$(pwd)/stationxml.conf:/opt/stationxml.conf"
DOCKER_VOLUME_1="-v \$(pwd)/OUTPUT:/opt/OUTPUT"
DOCKER_NAME="stationxml2seed:1.0"
cat << EOF

 This docker could be run as "Web Service" or "CLI"
 This docker search the given STATIONXML_PARAMETERS on StationXML and convert it to RESP or DATALESS files or DATASELECT_LIST list.

 usage in "cli" mode: ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -m "cli"

    Values for option -t: resp, dless, dataselect_list, miniseed, sac

    Examples:
     1) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -m "cli" -u "network=IV&station=ACER&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "dataselect_list"
     2) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -m "cli" -u "network=IV&latitude=42&longitude=12&maxradius=1" -t "dataselect_list"
     3) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -m "cli" -u "network=IV&latitude=47.12&longitude=11.38&maxradius=0.5&channel=HH?,EH?,HN?" -t "dataselect_list"
     4) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -m "cli" -u "network=IV&station=ACER&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00&channel=L??" -t "dless"
     5) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -m "cli" -u "latitude=-3.66&longitude=127.92&maxradius=2&channel=HH?,EH?,HN?&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "dataselect_list"
     6) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -m "cli" -u "latitude=-3.66&longitude=127.92&maxradius=2&channel=HH?,EH?,HN?&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "resp"
     7) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -m "cli" -u "latitude=-3.66&longitude=127.92&maxradius=2&channel=HH?,EH?,HN?&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "miniseed"

     8) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -m "cli" -u "latitude=-3.66&longitude=127.92&maxradius=2&channel=HH?,EH?,HN?&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "sac"
          Note: before request SAC you need request dataless by -t "dless"

 usage in "ws" mode: ${BASE_COMMAND} {DOCKER_NAME} -m "ws"
    Examples:
     1) http://<host>:8888/query?net=IV&sta=ACER&type=resp
     2) http://<host>:8888/query?net=IV&sta=ACER&type=dless

    with "ws" option, you must expose the Docker port with command '-p 8888:8888', then connect to: http://<host>:8888/query?params=<StationXML_paramenters>&type=<type>

EOF
}

### START - Check parameters ###
IN__STATIONXML_URL=
IN__TYPE=
while getopts :u:t: OPTION
do
	case ${OPTION} in
		u)	IN__STATIONXML_URL="${OPTARG}"
			;;
        t)	IN__TYPE="${OPTARG}"
			;;
        \?) echo "Invalid option: -$OPTARG" >/dev/null
			shift
			;;
        *)  #echo $OPTARG >/dev/null
			echo "Invalid OPTARG: -$OPTARG" >&2
            ;;
	esac
done

# Check input parameter
if [[ -z ${IN__STATIONXML_URL} ]]; then
        echo ""
        echo " Please, set the STATIONXML_URL param"
        echo ""
        usage_entrypoint
        exit 1
fi
if [[ -z ${IN__TYPE} ]]; then
	TYPE="resp"
else
	if [[ "${IN__TYPE}" == "resp" ]] || [[ "${IN__TYPE}" == "dless" ]] || [[ "${IN__TYPE}" == "dataselect_list" ]] || [[ "${IN__TYPE}" == "miniseed" ]] || [[ "${IN__TYPE}" == "sac" ]]; then
		TYPE=${IN__TYPE} 
	else
        echo ""
        echo " Please, set the TYPE param"
        echo ""
        usage_entrypoint
        exit 1
	fi
fi

# Create dir
if [ ! -d ${DIR_LOG} ]; then
	mkdir -p ${DIR_LOG}
fi
if [ ! -d ${DIR_OUTPUT} ]; then
    mkdir -p ${DIR_OUTPUT}
fi
if [ ! -d ${DIR_TMP} ]; then
    mkdir -p ${DIR_TMP}
fi


# Set software
STATIONXML_TO_SEED="java -jar ./stationxml-converter-1.0.9.jar -s"
SEED_2_OUTPUT="rdseed -R"

# Set StationXML config file
echo "StationXML used to find NETWORK/STATION (update your \"stationxml.conf\" file to add more)"
cat ${FILE_FDSNWS_NODES_URLS}
echo ""

# Parse input URL
STATIONXML_PARAMS=
STARTTIME="$( date +%Y-%m-%d )T00:00:00"
ENDTIME="$( date +%Y-%m-%d )T23:59:59"
NETWORK='*'
STATION='*'
CHANNEL='*'

set -f   # disable wildcard expansion
ARRAY_URL_TMP=(${IN__STATIONXML_URL//[=&]/ })
set +f   # restore wildcard expansion

for ((i=0; i<${#ARRAY_URL_TMP[@]}; i+=2))
do
	if [[ "${ARRAY_URL_TMP[i]}" == "level" ]] || [[ "${ARRAY_URL_TMP[i]}" == "format" ]]; then
		echo "" > /dev/null
	else
		STATIONXML_PARAMS="${STATIONXML_PARAMS}${ARRAY_URL_TMP[i]}=${ARRAY_URL_TMP[i+1]}&"
	fi
done
STATIONXML_PARAMS=${STATIONXML_PARAMS%?}

# 
STATIONXML_PARAMS_FIND="level=station&format=text&${STATIONXML_PARAMS}"

# Search StationXML that match IN__STATIONXML_URL
EXISTS=0
while read FDSNWS_NODE_URL; do
    STATIONXML_FULL_URL="${FDSNWS_NODE_URL}/fdsnws/station/1/query?${STATIONXML_PARAMS_FIND}"
    echo "Searching on \"${STATIONXML_FULL_URL}\""
    curl "${STATIONXML_FULL_URL}" -o "${FILE_CURL1}" --write-out "%{http_code}\\n" > ${FILE_CURL1_HTTPCODE} -s
    RETURNED_CODE=${?}

    HTTP_CODE=$( cat ${FILE_CURL1_HTTPCODE} )
    if (( ${RETURNED_CODE} == 0 )) && (( ${HTTP_CODE} == 200 )); then
        echo " FOUND!"
        EXISTS=1

        # get node host (ie: rtserve.beg.utexas.edu, eida.ipgp.fr, webservices.ingv.it, ...)
        FDSNWS_NODE=${FDSNWS_NODE_URL#*//} #removes stuff upto // from begining
        FDSNWS_NODE=${FDSNWS_NODE%/*} #removes stuff from / all the way to end

        # set full path
        FDSNWS_NODE_PATH=${DIR_TMP}/${FDSNWS_NODE}

        # create dir
        if [ ! -d ${FDSNWS_NODE_PATH} ]; then
            mkdir -p ${FDSNWS_NODE_PATH}
        fi

        # create 'stationxml_station.txt' file with the name of fdsnws node
        echo ${STATIONXML_FULL_URL} > ${FDSNWS_NODE_PATH}/stationxml_station.txt

        # Remove comment line from StationXML 'text' output
        grep -v ^# ${FILE_CURL1} > ${FILE_CURL1}.new
        mv ${FILE_CURL1}.new ${FILE_CURL1}

        # Get only NETWORK and STATION, Sort and Unique
        cat ${FILE_CURL1} | awk -F"|" '{print $1"|"$2}' | sort -u > ${FILE_CURL1}.new
        mv ${FILE_CURL1}.new ${FILE_CURL1}

        # create 'net_sta.txt' file with only NET and STA for that node
        cp ${FILE_CURL1} ${FDSNWS_NODE_PATH}/net_sta.txt
        
    fi
done < ${FILE_FDSNWS_NODES_URLS}
echo ""

if (( ${EXISTS} == 1 )); then
    if [[ "${TYPE}" == "resp" ]] || [[ "${TYPE}" == "dless" ]]; then
        ${DIR_WORK}/02_get_dless-resp.sh -t ${TYPE}
    elif [[ "${TYPE}" == "sac" ]]; then
        ${DIR_WORK}/02_get_dless-resp.sh -t ${TYPE}
        ${DIR_WORK}/03_get_dataselect_list-mseed-sac.sh -t ${TYPE}
    elif [[ "${TYPE}" == "dataselect_list" ]] || [[ "${TYPE}" == "miniseed" ]]; then
        ${DIR_WORK}/03_get_dataselect_list-mseed-sac.sh -t ${TYPE}
        if [[ "${TYPE}" == "dataselect_list" ]]; then
            for FDSNWS_NODE_PATH in $( ls -d ${DIR_TMP}/* ); do
                cat ${FDSNWS_NODE_PATH}/dataselect_urls.txt
            done
        fi
    fi
else 
    echo ""
    echo "There are no FDSNWS_NODE_URL that contains \"${STATIONXML_PARAMS}\"."
    echo ""
    exit -1
fi

# Remove temporary files/directories
#if [ -d ${DIR_TMP} ]; then
#    rm -fr ${DIR_TMP}
#fi