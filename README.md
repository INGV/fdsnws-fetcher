# fdsnws-fetcher

This Docker is used to retrieve:
- "**resp**": Response file
- "**dless**": Dataless file
- "**sac**": Dataless file
- "**dataselect_list**" A list of **dataselect** URL to download required MSEED

sending a request to each "**station**" FDSNS-WS to find available stations.

## Quickstart
### Build docker
```
$ git clone git@gitlab.rm.ingv.it:docker/fdsnws-fetcher.git
$ cd fdsnws-fetcher
$ docker build --tag fdsnws-fetcher:1.0 . 
```

in case of errors, try:
```
$ docker build --no-cache --pull --tag fdsnws-fetcher:1.0 . 
```

### Update `stationxml.conf`
Update your `stationxml.conf` adding more StationXML entry point

### Run docker
This docker can be run via **Web Services** or via **CLI**
```
$ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf fdsnws-fetcher:1.0

 This docker could be run as "Web Service" or "CLI"
 This docker search the given STATIONXML_PARAMETERS on StationXML and convert it to RESP or DATALESS files or DATASELECT_LIST list.

 usage in "cli" mode: docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf fdsnws-fetcher:1.0
    Examples:
     1) $ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf fdsnws-fetcher:1.0 -u "network=IV&station=ACER&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "dataselect_list"
     2) $ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf fdsnws-fetcher:1.0 -u "network=IV&latitude=42&longitude=12&maxradius=1" -t "dataselect_list"
     3) $ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf fdsnws-fetcher:1.0 -u "network=IV&latitude=47.12&longitude=11.38&maxradius=0.5&channel=HH?,EH?,HN?" -t "dataselect_list"
     4) $ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf fdsnws-fetcher:1.0 -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "resp" 
     5) $ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf fdsnws-fetcher:1.0 -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "miniseed"
     6) $ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf fdsnws-fetcher:1.0 -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "sac"
     7) $ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf fdsnws-fetcher:1.0 -u "network=IV,MN&station=BLY&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "dless"
$
```

check your `./OUTPUT` local directory.

### Enter into the Docker
To override the `ENTRYPOINT` directive and enter into the Docker images, run:
```
$ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf --entrypoint=bash fdsnws-fetcher:1.0
```

# Contribute
Please, feel free to contribute.
