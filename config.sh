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
STATIONXML_TO_SEED="java -jar ./stationxml-converter-1.0.9.jar -s"
RDSEED="rdseed -R"
