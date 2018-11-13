#!/bin/bash
#
#
# xml2seed.sh
#
# This script helps staging of station response metadata to a local storage.
# It uses an FDSN station service to download station metadata in StationXML
# and converts them in the desired format, here RESP files.
#
# (c) 2017 Peter Danecek <peter.danecek@ingv.it> and Valentino Lauciani <valentino.lauciani@ingv.it>, Istituto Nazione di Geofisica e Vulcanologia.
#
#####################################################3

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
                m)      IN__MODE="${OPTARG}"
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
if [[ -z ${IN__MODE} ]]; then
        echo ""
        echo " Please, set the MODE (-m) option"
        echo ""
        usage_entrypoint
        exit 1
fi

#
if [[ "${IN__MODE}" == "ws" ]]; then
	python ads_services.py
else
	./01_find_stations.sh $@
fi
