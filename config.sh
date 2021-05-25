#!/bin/bash

# Set date
export DATE_NOW=${DATE_NOW:=$(date +%Y%m%d_%H%M%S)}

# Set dir name
DIR_WORK=$( cd $( dirname $0 ) && pwd )
DIR_OUTPUT="${DIR_WORK}/OUTPUT/${DATE_NOW}"
DIR_TMP="${DIR_WORK}/tmp/${DATE_NOW}"
DIR_LOG="${DIR_WORK}/log/${DATE_NOW}"

# Set file name
FILE_FDSNNODE_STATION="${DIR_LOG}/$(basename $0)__FDSNNODE_STATION.txt"
FILE_CURL1="${DIR_LOG}/$(basename $0)__FILE_CURL1.log"
FILE_CURL1_HTTPCODE="${DIR_LOG}/$(basename $0)__FILE_CURL1.http_code"
FILE_CURL2="${DIR_LOG}/$(basename $0)__FILE_CURL2.log"
FILE_CURL2_HTTPCODE="${DIR_LOG}/$(basename $0)__FILE_CURL2.http_code"
FILE_FDSNWS_NODES_URLS="stationxml.conf"

# Set software
#STATIONXML_TO_SEED="java -jar ./stationxml-converter-1.0.10.jar -s"
STATIONXML_TO_SEED="java -jar ./stationxml-seed-converter-2.1.0.jar"
RDSEED="rdseed"

# Set var
N_PROCESS_TO_GET_DLESS=20

# Functions
function usage_entrypoint() {
BASE_COMMAND="docker run -it --rm --user \$(id -u):\$(id -g) -v \$(pwd)/${FILE_FDSNWS_NODES_URLS}:/opt/${FILE_FDSNWS_NODES_URLS}"
DOCKER_VOLUME_1="-v \$(pwd)/OUTPUT:/opt/OUTPUT"
DOCKER_VOLUME_2="-v \$(pwd)/my_token:/opt/token"
DOCKER_NAME="ingv/fdsnws-fetcher"
cat << EOF

 This docker search the given STATIONXML_PARAMETERS on StationXML and convert it to RESP or DATALESS files or DATASELECT_LIST list.

  Print software version number: 
  $ docker run -it --rm ${DOCKER_NAME} -v

  Usage:
  $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -u <stationxml params>

    Values for option -t: resp, paz, dless, dataselect_list, miniseed, sac

    Examples:
     1) $ docker run -it --rm ${DOCKER_NAME} -v
     2) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -u "network=IV&station=ACER&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "dataselect_list"
     3) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -u "network=IV&latitude=42&longitude=12&maxradius=1" -t "dataselect_list"
     4) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -u "network=IV&latitude=47.12&longitude=11.38&maxradius=0.5&channel=HH?,EH?,HN?" -t "dataselect_list"
     5) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -u "network=IV,MN&station=BLY&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "dless"
     6) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "resp,dless"
     7) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "miniseed,resp"
     8) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_NAME} -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "sac,dataselect_list"

    Example with auth token for restricted stations:
     1) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_VOLUME_2} ${DOCKER_NAME} -u "network=IV&station=ACER&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "dataselect_list"
     2) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_VOLUME_2} ${DOCKER_NAME} -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "miniseed,resp"
     3) $ ${BASE_COMMAND} ${DOCKER_VOLUME_1} ${DOCKER_VOLUME_2} ${DOCKER_NAME} -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "sac"


EOF
}

function check_type() {
	TYPE=${1}
        
	if [[ "${TYPE}" == "resp" ]] || [[ "${TYPE}" == "dless" ]] || [[ "${TYPE}" == "dataselect_list" ]] || [[ "${TYPE}" == "miniseed" ]] || [[ "${TYPE}" == "sac" ]] || [[ "${TYPE}" == "paz" ]]; then
		return 0
        else
		return 1
        fi
}
