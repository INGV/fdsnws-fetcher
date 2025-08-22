#FROM debian:bullseye
FROM debian:bookworm

LABEL maintainer="Valentino Lauciani <valentino.lauciani@ingv.it>"

ENV DEBIAN_FRONTEND=noninteractive
ENV INITRD=No
ENV FAKE_CHROOT=1

ARG TARGETPLATFORM

# Print ARCHITECTURE variable
RUN echo "Detected architecture: $(uname -m)"

# install packages
RUN apt-get update \
    && apt-get install -y \
    vim \
    git \
    telnet \
    dnsutils \
    wget \
    curl \
    default-jre \
    apt-transport-https \
    procps \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN apt-get update \
    && apt-get install -y \
    python3-dev \
    python3-pycurl \
    python3-simplejson \
    libcurl4-gnutls-dev \
    libssl-dev \
    python3 \
    python3-psutil \
    python3-requests \
    python3-jsonschema \
    python3-setuptools \
    python3-dev \
    python3-pip \
    build-essential \
    libxml2-dev \
    libxslt1-dev \
    libz-dev \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Upgrade pip
RUN python3 -m pip install --upgrade pip

# Set .bashrc
RUN echo "" >> /root/.bashrc \
    && echo "##################################" >> /root/.bashrc \
    && echo "alias ll='ls -l --color'" >> /root/.bashrc \
    && echo "" >> /root/.bashrc \
    && echo "export LC_ALL=\"C\"" >> /root/.bashrc \
    && echo "" >> /root/.bashrc

# Set 'root' pwd
RUN echo root:toor | chpasswd

# Get and install rdseed
WORKDIR /opt
COPY soft/rdseedv5.3.1.tar.gz /opt/
RUN tar xvzf rdseedv5.3.1.tar.gz \
    && rm /opt/rdseedv5.3.1.tar.gz \
    && cd /usr/bin \
    && ln -s /opt/rdseedv5.3.1/rdseed.rh6.linux_64 rdseed

# Install qlib
WORKDIR /opt
COPY soft/qlib2.2019.365.tar.gz /opt/
RUN tar xvzf qlib2.2019.365.tar.gz \
    && rm qlib2.2019.365.tar.gz \
    && cd qlib2 \
    && cp Makefile Makefile.original \
    && sed -e 's|ROOTDIR\s=.*|ROOTDIR = /usr/local|' -e 's|LEAPSECONDS\s=.*|LEAPSECONDS = /usr/local/etc/leapseconds|' Makefile > Makefile.new \
    && mv Makefile.new Makefile \
    && ARCHITECTURE=$(uname -m) \
    && if [ "${ARCHITECTURE}" = "aarch64" ]; then \
        sed -e 's|C64\s=.*|C64 = |' Makefile > Makefile.new \
        && mv Makefile.new Makefile ; \
    fi \ 
    && mkdir /usr/local/share/man/man3/ \
    && mkdir /usr/local/lib64 \
    && make clean \
    && make all64 \
    && make install64 \
    && rm -fr /opt/qlib2

# Install qmerge
WORKDIR /opt
COPY soft/qmerge.2014.329.tar.gz /opt/
RUN tar xvzf qmerge.2014.329.tar.gz \
    && rm qmerge.2014.329.tar.gz \
    && cd qmerge \
    && cp Makefile Makefile.original \
    && sed -e 's|^QLIB2.*|QLIB2 = /usr/local/lib64/libqlib2.a|' Makefile > Makefile.new \
    && mv Makefile.new Makefile \
    && ARCHITECTURE=$(uname -m) \
    && if [ "${ARCHITECTURE}" = "aarch64" ]; then \
        sed -e 's|^CC.*|CC = cc -Wall|' Makefile > Makefile.new \
        && mv Makefile.new Makefile ; \
    fi 
# Fix for multiple definition error of 'qverify' and 'verify' variables during linking.
# This modifies 'externals.h' to declare 'qverify' and 'verify' as external variables 
# and adds their actual definitions in 'qmerge.c' to avoid reallocation issues.
WORKDIR /opt/qmerge
RUN sed -i '/int qverify;/s/^/extern /' ./externals.h \
    && sed -i '/struct _verify {/s/^/extern /' ./externals.h \
    && sed -i '/#include "externals.h"/a \ \nint qverify = 0;\nstruct _verify verify;\n' ./qmerge.c \
    && make clean \
    && make install \
    && rm -fr /opt/qmerge
WORKDIR /opt

# Install ObsPy
RUN pip3 install obspy

# Get and install PyRocko - https://pyrocko.org/docs/current/install/system/linux/index.html
WORKDIR /opt
RUN apt-get update \
    && apt-get install -y \
    make \
    git \
    python3-dev \
    python3-setuptools \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* 
RUN apt-get update \
    && apt-get install -y \
    python3-numpy \
    python3-numpy-dev \
    python3-scipy \
    python3-matplotlib \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*
#RUN apt-get update \
#    && apt-get install -y \
#    python3-pyqt4 \
#    python3-pyqt4.qtopengl \
#    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*
RUN apt-get update \
    && apt-get install -y \
    python3-pyqt5 \
    python3-pyqt5.qtopengl \
    python3-pyqt5.qtsvg \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*
RUN apt-get update \
    && apt-get install -y \
    python3-pyqt5.qtwebengine || apt-get install -y python3-pyqt5.qtwebkit
RUN apt-get update \
    && apt-get install -y \
    python3-yaml \
    python3-progressbar \
    python3-jinja2 \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*
RUN apt-get update \
    && apt-get install -y \
    python3-requests \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*
COPY soft/pyrocko_v2024.01.10bis.tar.gz /opt/
RUN tar xvzf pyrocko_v2024.01.10bis.tar.gz \
    && rm pyrocko_v2024.01.10bis.tar.gz \ 
    && cd pyrocko* \
    && python3 setup.py install
WORKDIR /
RUN mkdir /.pyrocko/ \
    && chmod 777 /.pyrocko/

# Get last leapseconds
WORKDIR /tmp
RUN wget -O /tmp/leapseconds http://www.ncedc.org/ftp/pub/programs/leapseconds
RUN chmod 777 /tmp/leapseconds

# Install Xml2Resp and scripts
WORKDIR /opt
COPY soft/stationxml-converter-1.0.10.jar /opt/
COPY soft/stationxml-seed-converter-2.1.0.jar /opt/
COPY 01_find_stations.sh /opt/
COPY 02_get_dless-resp-paz.sh /opt/
COPY 021_get_dless-resp-paz_parallel.sh /opt/
COPY 03_get_dataselect_list-mseed-sac.sh /opt/
COPY 031_get_mseed-sac_parallel.sh /opt/
COPY entrypoint.sh /opt/
COPY config.sh /opt/
COPY seed_handler.py /opt/
COPY publiccode.yml /opt/
RUN chmod 755 /opt/01_find_stations.sh
RUN chmod 755 /opt/02_get_dless-resp-paz.sh
RUN chmod 755 /opt/021_get_dless-resp-paz_parallel.sh
RUN chmod 755 /opt/03_get_dataselect_list-mseed-sac.sh
RUN chmod 755 /opt/031_get_mseed-sac_parallel.sh
RUN chmod 755 /opt/seed_handler.py
RUN chmod 755 /opt/publiccode.yml
RUN chmod 777 /opt

# Fix permissions problem on log file 'seed_handler.Log'
RUN sed -i "s|logfn=open('seed_handler.Log','w')|logfn=open('/tmp/seed_handler.Log','w')|" seed_handler.py


# Create OUTPUT dir 
WORKDIR /opt
RUN mkdir /opt/OUTPUT
RUN chmod -R 777 /opt/OUTPUT

#
RUN echo "BUILDPLATFORM=${BUILDPLATFORM}" > /tmp/arc
RUN echo "TARGETPLATFORM=${TARGETPLATFORM}" >> /tmp/arc
RUN echo "TARGETOS=${TARGETOS}" >> /tmp/arc
RUN echo "TARGETARCH=${TARGETARCH}" >> /tmp/arc
RUN uname -m >> /tmp/arc

# Set entrypoint
ENTRYPOINT ["./entrypoint.sh"]
