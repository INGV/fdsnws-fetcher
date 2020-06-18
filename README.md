[![TeamDigitale](https://img.shields.io/badge/publiccode%20compliant-%E2%9C%94-blue.svg?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAMAAAAolt3jAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAFxUExURQBmzABmzABmzABkywBkywBmzABmzABmzApszj2L2CyA1QBmzABmzABmzABlzABkywBlzABmzABkywBkywBkyyZ91OXv+qTH7AJlzABlzABmzABlzBJx0Hiu5EyU2wBmzECM2Wil4RRy0CZ91Orz+8/i9W2n4h950gBlzABkyzuJ2Pb6/bbT8AVpzZbA6vX5/TOE1iR80+jx+vn8/uXv+kKO2QBjywBlzA9vz3Cp4kmS2wBlzJbA6vX5/TOE1uvz+7LR8Ch+1AttzgBmzABmzABkywBkywBlzJbA6uz0+6PH7AFlzABmzABmzABlzJbA6jOE1iR70+z0+6TH7AFky5bA6jOF1hx30uPu+c/i9V+f3xl10QBlzABmzABlzIi459/s+TCD1gVpzZ7F7Pb6/evz+0CM2QBjywBmzBd00SV80whrzgBlzBFwzzqJ2DaG1wttzgBmzABmzABlzABlzABmzABmzABkywBkywBmzP///7f5b6EAAAABYktHRHo41YVqAAAAB3RJTUUH4wUWBTMYAFp7MgAAAF50RVh0UmF3IHByb2ZpbGUgdHlwZSBpcHRjAAppcHRjCiAgICAgIDI4CjM4NDI0OTRkMDQwNDAwMDAwMDAwMDAwZjFjMDI2ZTAwMDM1MjQ2NDcxYzAyMDAwMDAyMDAwNDAwCmCaPZ4AAAClSURBVAjXY2DAChiZmFlYwSw2EMHOwcnFzcPAwMvHLyAoJCwiKiYuISnFIC0jKyevoKikrKKqpq7BoKmlraOrp29gaGRsYmrGYG5haWVtY2tnaO/g6OTMwOvi6ubuAeR6enn7+IJMZfXztw0IDAoOkZaCcEP1w8IjIqOiY0Dc2Lj4hMSk5JTUtHSwOzIys7JzcvPyCwrB7ioqLiktMy+vqPRFczoAaG4fQ5lQVPsAAAAldEVYdGRhdGU6Y3JlYXRlADIwMTktMDUtMjJUMDU6NTE6MjQtMDQ6MDDV7wZaAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDE5LTA1LTIyVDA1OjUxOjI0LTA0OjAwpLK+5gAAAABJRU5ErkJggg==)](https://developers.italia.it/it/software/ingv-ingv-fdsnws-fetcher)

[![License](https://img.shields.io/github/license/INGV/fdsnws-fetcher.svg)](https://github.com/INGV/fdsnws-fetcher/blob/master/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/INGV/fdsnws-fetcher.svg)](https://github.com/INGV/fdsnws-fetcher/issues)
[![Join the #general channel](https://img.shields.io/badge/Slack%20channel-%23general-blue.svg)](https://ingv-institute.slack.com/messages/CKS902Y5B)
[![Get invited](https://slack.developers.italia.it/badge.svg)](https://join.slack.com/t/ingv-institute/shared_invite/zt-ckoji8va-mutwycltiCw_EAhUWSND8Q)

![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/vlauciani/fdsnws-fetcher)
![Docker Image Size (latest semver)](https://img.shields.io/docker/image-size/vlauciani/fdsnws-fetcher?sort=semver)
![Docker Pulls](https://img.shields.io/docker/pulls/vlauciani/fdsnws-fetcher)

# fdsnws-fetcher [![Version](https://img.shields.io/badge/dynamic/yaml?label=ver&query=softwareVersion&url=https://raw.githubusercontent.com/INGV/fdsnws-fetcher/master/publiccode.yml)](https://github.com/INGV/fdsnws-fetcher/blob/master/publiccode.yml) [![CircleCI](https://circleci.com/gh/INGV/fdsnws-fetcher/tree/master.svg?style=svg)](https://circleci.com/gh/INGV/fdsnws-fetcher/tree/master)

This Docker is used to retrieve:
- "**resp**": Response file(s)
- "**paz**": Poles and zeros file(s)
- "**dless**": Dataless file(s)
- "**sac**": Dataless file(s)
- "**miniseed**": MiniSeed file(s)
- "**dataselect_list**": A list of **dataselect** URL used to download MiniSeed

sending a request to each "**station**" FDSNS-WS to find available stations.

## Quickstart
### Clone the repository
First, clone the git repositry:
```
$ git clone https://github.com/INGV/fdsnws-fetcher.git
$ cd fdsnws-fetcher
```

### Docker image
To obtain *fdsnws-fetcher* docker image, you have two options:

#### 1) Get built image
Get the last built image from dockerhub:
```
$ docker pull vlauciani/fdsnws-fetcher:latest
```

#### 2) Build by yourself
```
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

 This docker search the given STATIONXML_PARAMETERS on StationXML and convert it to RESP and/or DATALESS files and/or DATASELECT_LIST list.

 usage:
 $ docker run -it --user $(id -u):$(id -g) --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u <stationxml params>

    Values for option -t: resp, paz, dless, dataselect_list, miniseed, sac

    Examples:
     1) $ docker run -it --user $(id -u):$(id -g) --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u "network=IV&station=ACER&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "dataselect_list"
     2) $ docker run -it --user $(id -u):$(id -g) --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u "network=IV&latitude=42&longitude=12&maxradius=1" -t "dataselect_list"
     3) $ docker run -it --user $(id -u):$(id -g) --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u "network=IV&latitude=47.12&longitude=11.38&maxradius=0.5&channel=HH?,EH?,HN?" -t "dataselect_list"
     4) $ docker run -it --user $(id -u):$(id -g) --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u "network=IV,MN&station=BLY&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "dless"
     5) $ docker run -it --user $(id -u):$(id -g) --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "resp,dless"
     6) $ docker run -it --user $(id -u):$(id -g) --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "miniseed,resp"
     7) $ docker run -it --user $(id -u):$(id -g) --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT fdsnws-fetcher -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "sac,dataselect_list"

    Example with auth token for restricted stations:
     1) $ docker run -it --user $(id -u):$(id -g) --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/my_token:/opt/token fdsnws-fetcher -u "network=IV&station=ACER&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "dataselect_list"
     2) $ docker run -it --user $(id -u):$(id -g) --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/my_token:/opt/token fdsnws-fetcher -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "miniseed,resp"
     3) $ docker run -it --user $(id -u):$(id -g) --rm -v $(pwd)/stationxml.conf:/opt/stationxml.conf -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/my_token:/opt/token fdsnws-fetcher -u "lat=45.75&lon=11.1&maxradius=1&starttime=2017-11-02T00:00:00&endtime=2017-11-02T01:00:00" -t "sac"


$
```

The output data is into the `./OUTPUT` local directory.

### Example screenshot
![alt text](images/screen_output.png)

### Enter into the Docker
To override the `ENTRYPOINT` directive and enter into the Docker images, run:
```
$ docker run -it --user $(id -u):$(id -g) --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf --entrypoint=bash fdsnws-fetcher
```
or with `root`:
```
$ docker run -it --rm -v $(pwd)/OUTPUT:/opt/OUTPUT -v $(pwd)/stationxml.conf:/opt/stationxml.conf --entrypoint=bash fdsnws-fetcher
```

# Contribute
Please, feel free to contribute.

# Author
(c) 2019 Valentino Lauciani valentino.lauciani[at]ingv.it

Istituto Nazionale di Geofisica e Vulcanologia, Italia
