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
while getopts :o:u:t: OPTION
do
	case ${OPTION} in
        o)	FILE_OUTPUT_DLESS="${OPTARG}"
		;;
        u)	STATIONXML_INPUT_URL="${OPTARG}"
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
BASENAME_DLESS=$( basename ${FILE_OUTPUT_DLESS} )
DIRNAME_DLESS=$( dirname ${FILE_OUTPUT_DLESS} )
DIR_NODE=$( cd ${DIRNAME_DLESS} && cd ../ && pwd )
DIR_DLESS_LOG_NODE=${DIRNAME_DLESS}/log

# create dir
if [ ! -d ${DIR_DLESS_LOG_NODE} ]; then
    mkdir -p ${DIR_DLESS_LOG_NODE}
fi

echo " create DLESS \"${BASENAME_DLESS}\" from \"${STATIONXML_INPUT_URL}\""
if [[ -f ${FILE_OUTPUT_DLESS} ]]; then
	echo "  DLESS already exists"
else
	${STATIONXML_TO_SEED} -o ${FILE_OUTPUT_DLESS} "${STATIONXML_INPUT_URL}" >> ${DIR_DLESS_LOG_NODE}/${BASENAME_DLESS}.stationxml-converter.out 2>> ${DIR_DLESS_LOG_NODE}/${BASENAME_DLESS}.stationxml-converter.err
	RET_STATIONXML_TO_SEED=${?}
	if (( ${RET_STATIONXML_TO_SEED} != 0 )); then
    		echo "  ERROR - Retriving StationXML from \"${STATIONXML_INPUT_URL}\". Check: ${DIR_DLESS_LOG_NODE}/${BASENAME_DLESS}.stationxml-converter.err"
    		echo ""
	fi
fi

# Create RESP and/or PAZ
if [ -s ${FILE_OUTPUT_DLESS} ]; then
    if [[ "${TYPE}" == "resp" ]]; then
        DIR_RESP_NODE=${DIR_NODE}/resp
        if [ ! -d ${DIR_RESP_NODE} ]; then
            mkdir -p ${DIR_RESP_NODE}
        fi
        DIR_RESP_LOG_NODE=${DIR_RESP_NODE}/log
        if [ ! -d ${DIR_RESP_LOG_NODE} ]; then
            mkdir -p ${DIR_RESP_LOG_NODE}
        fi
        echo " create RESP from \"${FILE_OUTPUT_DLESS}\""
        ${RDSEED} -R -S -f ${FILE_OUTPUT_DLESS} -q ${DIR_RESP_NODE} >> ${DIR_RESP_LOG_NODE}/${BASENAME_DLESS}.rdseed.out 2>> ${DIR_RESP_LOG_NODE}/${BASENAME_DLESS}.rdseed.err
        RET_RDSEED=${?}
        if (( ${RET_RDSEED} != 0 )); then
            cat ${DIR_RESP_LOG_NODE}/${BASENAME_DLESS}.rdseed.err
            echo -e "\n"
        fi
        if [[ -f ${DIR_RESP_NODE}/rdseed.stations ]]; then
            cat ${DIR_RESP_NODE}/rdseed.stations >> ${DIR_RESP_NODE}/rdseed.stations.info
            rm ${DIR_RESP_NODE}/rdseed.stations
        fi
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
        echo " create PAZ from \"${FILE_OUTPUT_DLESS}\""
        ${RDSEED} -p -f ${FILE_OUTPUT_DLESS} -q ${DIR_PAZ_NODE} >> ${DIR_PAZ_LOG_NODE}/${BASENAME_DLESS}.rdseed.out 2>> ${DIR_PAZ_LOG_NODE}/${BASENAME_DLESS}.rdseed.err
        RET_RDSEED=${?}
        if (( ${RET_RDSEED} != 0 )); then
            cat ${DIR_PAZ_LOG_NODE}/${BASENAME_DLESS}.rdseed.err
            echo -e "\n"
        fi
    fi
fi


