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
        echo "${DATASELECT_URL}" >> ${FDSNWS_NODE_PATH}/dataselect_urls.txt

        if [[ "${TYPE}" == "miniseed" ]] || [[ "${TYPE}" == "sac" ]]; then
            # create MSEED dir
            DIR_MSEED_NODE=${FDSNWS_NODE_PATH}/mseed
            mkdir -p ${DIR_MSEED_NODE}

            #
            OUTPUTMINISEED="${DIR_MSEED_NODE}/${NETWORK}.${STATION}.${LOCATION}.${CHANNEL}.mseed"
            OUTPUTDATALESS="${FDSNWS_NODE_PATH}/dless/${NETWORK}_${STATION}.dless"
            curl "${DATASELECT_URL}" -o "${OUTPUTMINISEED}" --write-out "%{http_code}\\n" > ${FILE_CURL2_HTTPCODE} -s
            RET_CODE=$?
            HTTP_CODE=$( cat ${FILE_CURL2_HTTPCODE} )
            if [ ${RET_CODE} -eq 0 ] && [ ${HTTP_CODE} -eq 200 ]; then
                if [ -f ${OUTPUTMINISEED} ]; then
                    echo "OK - file ${OUTPUTMINISEED} successfully downloaded."
                fi
                if [[ "${TYPE}" == "sac" ]]; then
                    if [ -f ${OUTPUTDATALESS} ]; then
                        # create SAC dir
                        DIR_SAC_NODE=${FDSNWS_NODE_PATH}/sac
                        if [ ! -d ${DIR_SAC_NODE} ]; then
                            mkdir -p ${DIR_SAC_NODE}
                        fi
                        ${RDSEED} -o SAC -q ${DIR_SAC_NODE} -d -f ${OUTPUTMINISEED} -g ${OUTPUTDATALESS}
                        RET=$?
                        if [ $RET -ne 0 ]; then
                            echo " ERROR - converting ${OUTPUTMINISEED} to SAC format."
                        fi
                    else
                        echo " ERROR - skip SAC conversion. File ${OUTPUTDATALESS} not found."
                    fi
                fi
            elif [ ${RET_CODE} -eq 0 ] && [ ${HTTP_CODE} -eq 204 ]; then
                echo "NODATA - requesting ${DATASELECT_URL}"
                echo "         return RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}"
                if [ -f ${OUTPUTMINISEED} ]; then
                    rm -f ${OUTPUTMINISEED}
                fi
                echo ""
            else
                echo "ERROR - requesting ${DATASELECT_URL}"
                echo "        return RET_CODE=${RET_CODE}, HTTP_CODE=${HTTP_CODE}"
                if [ -f ${OUTPUTMINISEED} ]; then
                    rm -f ${OUTPUTMINISEED}
                fi
                echo ""
            fi
        fi
    done < ${FDSNWS_NODE_PATH}/stationxml_channel.txt
done
echo ""