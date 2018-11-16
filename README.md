# docker_StationXML2SEED

This Docker is used to retrieve:
- "**resp**": Response file
- "**dless**": Dataless file
- "**fullseed**": Dataless file
- "**sac**": Dataless file
- "**dataselect_list**" A list of **dataselect** URL to download required MSEED

sending a request to each "**station**" FDSNS-WS to find available stations.

## Quickstart
### Build docker
```
$ git clone git@gitlab.rm.ingv.it:docker/fdsnws_fetcher.git
$ cd fdsnws_fetcher
$ docker build --tag fdsnws_fetcher:1.0 . 
```

in case of errors, try:
```
$ docker build --no-cache --pull --tag fdsnws_fetcher:1.0 . 
```

### Update `stationxml.conf`
Update your `stationxml.conf` adding more StationXML entry point

### Run docker
This docker can be run via **Web Services** or via **CLI**
```
$ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0

 This docker could be run as "Web Service" or "CLI"
 This docker search the given STATIONXML_PARAMETERS on StationXML and convert it to RESP or DATALESS files or DATASELECT_LIST list.

 usage in "cli" mode: docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0 -m "cli"
    Examples:
     1) $ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0 -m "cli" -u "network=IV&station=ACER&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "dataselect_list"
     2) $ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0 -m "cli" -u "network=IV&latitude=42&longitude=12&maxradius=1" -t "dataselect_list"
     3) $ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0 -m "cli" -u "network=IV&latitude=47.12&longitude=11.38&maxradius=0.5&channel=HH?,EH?,HN?" -t "dataselect_list"
     4) $ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0 -m "cli" -u "network=IV&station=ACER&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00&channel=L??" -t "dless"
     5) $ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0 -m "cli" -u "latitude=-3.66&longitude=127.92&maxradius=2&channel=HH?,EH?,HN?&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "dataselect_list"
     6) $ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0 -m "cli" -u "latitude=-3.66&longitude=127.92&maxradius=2&channel=HH?,EH?,HN?&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "resp"

 usage in "ws" mode: docker run -it --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0 -m "ws"
    Examples:
     1) http://<host>:8888/query?net=IV&sta=ACER&typo=resp
     2) http://<host>:8888/query?net=IV&sta=ACER&typo=dless

    with "ws" option, you must expose the Docker port with command '-p 8888:8888', then connect to: http://<host>:8888/query?params=<StationXML_paramenters>&type=<type>

$
```

#### Web Serices mode 
Run the command:
```
$ docker run -it -p 8888:8888 -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0 -m "ws"
```

and open the URL:
- `http://<host>:8888/query?net=IV&sta=ACER&typo=resp`
- `http://<host>:8888/query?net=IV&sta=ACER&typo=dless`

#### CLI mode
Run the command:
```
$ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0 -m "cli" -u "network=IV&station=ACER&endtime=2017-11-02T01:00:00" -t "dataselect_list"
$ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0 -m "cli" -u "network=IV&latitude=42&longitude=12&maxradius=1" -t "dataselect_list"
$ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0 -m "cli" -u "network=IV&latitude=47.12&longitude=11.38&maxradius=0.5&channel=HH?,EH?,HN?" -t "dataselect_list"
$ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0 -m "cli" -u "network=IV&station=ACER&endtime=2017-11-02T01:00:00&channel=L??" -t "dless"
$ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0 -m "cli" -u "latitude=-3.66&longitude=127.92&maxradius=2&channel=HH?,EH?,HN?" -t "dataselect_list"
$ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf stationxml2seed:1.0 -m "cli" -u "latitude=-3.66&longitude=127.92&maxradius=2&channel=HH?,EH?,HN?" -t "resp"
```
check your `./OUTPUT` local directory.

### Enter into the Docker
To override the `ENTRYPOINT` directive and enter into the Docker images, run:
```
$ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf --entrypoint=bash stationxml2seed:1.0
```

# Contribute
Please, feel free to contribute.
