# fdsnws-fetcher

This Docker is used to retrieve:
- "**resp**": Response file(s)
- "**dless**": Dataless file(s)
- "**sac**": Dataless file(s)
- "**miniseed**": MiniSeed file(s)
- "**dless_and_miniseed**": Dataless and MiniSeed file(s)
- "**dataselect_list**": A list of **dataselect** URL used to download MiniSeed

sending a request to each "**station**" FDSNS-WS to find available stations.

## Quickstart
### Build docker
Clone this repository, then:

```
$ cd fdsnws-fetcher
$ docker build --tag fdsnws-fetcher . 
```

in case of errors, try:
```
$ docker build --no-cache --pull --tag fdsnws-fetcher . 
```

### Update `stationxml.conf`
Update your `stationxml.conf` adding more StationXML entry point

### Run docker
Running the command below to see the **help**:
```
$ docker run -it --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -h

 This docker search the given STATIONXML_PARAMETERS on StationXML and convert it to RESP or DATALESS files or DATASELECT_LIST list.

 usage:
 $ docker run -it --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u <stationxml params>

    Values for option -t: resp, dless, dataselect_list, miniseed, dless_and_miniseed, sac

    Examples:
     1) $ docker run -it --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u "network=IV&station=ACER&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "dataselect_list"
     2) $ docker run -it --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u "network=IV&latitude=42&longitude=12&maxradius=1" -t "dataselect_list"
     3) $ docker run -it --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u "network=IV&latitude=47.12&longitude=11.38&maxradius=0.5&channel=HH?,EH?,HN?" -t "dataselect_list"
     4) $ docker run -it --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u "network=IV,MN&station=BLY&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "dless"
     5) $ docker run -it --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "resp"
     6) $ docker run -it --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "miniseed"
     7) $ docker run -it --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "sac"


$
```

The output data is into the `./OUTPUT` local directory.

### Enter into the Docker
To override the `ENTRYPOINT` directive and enter into the Docker images, run:
```
$ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf --entrypoint=bash fdsnws-fetcher
```

# Contribute
Please, feel free to contribute.
