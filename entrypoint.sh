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

### START - Check parameters ###
#echo "Print all input params:${@}"
IN__MODE=
while getopts :hm: OPTION
do
        case ${OPTION} in
            h)
                usage_entrypoint
                exit 1
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >/dev/null
                ;;
    		:)
      			echo "Option -$OPTARG requires an argument." >&2
                usage_entrypoint
     			exit 1
      			;;
        esac
done
OPTIND=1

# Check input parameter
if [[ -z ${@} ]]; then
        echo ""
        echo " Please, give me an input params"
        echo ""
        usage_entrypoint
        exit 1
fi

# run command
time ./01_find_stations.sh $@
