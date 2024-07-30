#!/bin/bash
#
#
# (c) 2024 Valentino Lauciani <valentino.lauciani@ingv.it>,
#          Istituto Nazione di Geofisica e Vulcanologia.
# 
#####################################################

# Import config file
. $(dirname $0)/config.sh

# Check leapsecond
if [ "$( id -u )" -eq 0 ]; then
    qmerge -h 2> /dev/null > /dev/null
    if (( ${?} != 0 )); then
        wget -O /usr/local/etc/leapseconds http://www.ncedc.org/ftp/pub/programs/leapseconds
    fi
fi

# Get remote version number and check update
VERSION_GITHUB=$( curl -s https://raw.githubusercontent.com/INGV/fdsnws-fetcher/master/publiccode.yml | grep "softwareVersion" | awk -F":" '{print $2}' | sed -e 's/^[[:space:]]*//' )
if [ "${VERSION}" != "${VERSION_GITHUB}" ]; then
    echo ""
    echo "############################################################################"
    echo "# "
    echo "# Your current version: ${VERSION}"
    echo "# New available version: ${VERSION_GITHUB}"
    echo "# "
    echo "# Please, update your docker image running command below and try again!"
    echo "# $ docker pull ingv/fdsnws-fetcher"
    echo "#"
    echo "############################################################################"
    sleep 10
    #exit 1
fi

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
