FROM debian:stretch

LABEL maintainer="Valentino Lauciani <valentino.lauciani@ingv.it>"

ENV DEBIAN_FRONTEND=noninteractive
ENV INITRD No
ENV FAKE_CHROOT 1
ENV STATIONXML_CONVERTER=https://github.com/iris-edu/stationxml-seed-converter/releases/download/1.0.10/stationxml-converter-1.0.10.jar

# install packages
RUN apt-get update \
    && apt-get dist-upgrade -y --no-install-recommends \
    && apt-get install -y \
        vim \
        git \
        telnet \
        dnsutils \
        wget \
        curl \
        default-jre \
        procps

RUN apt-get install -y \
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
	build-essential \
	libxml2-dev \
	libxslt1-dev \
	libz-dev

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
    && sed -e 's|ROOTDIR\s=.*|ROOTDIR = /usr/local|' -e 's|LEAPSECONDS\s=.*|LEAPSECONDS = /usr/local/etc/leapseconds|' Makefile > Makefile.new \
    && mv Makefile Makefile.original \
    && mv Makefile.new Makefile \
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
    && sed -e 's|^QLIB2.*|QLIB2 = /usr/local/lib64/libqlib2.a|' Makefile > Makefile.new \
    && mv Makefile Makefile.original \
    && mv Makefile.new Makefile \
    && make clean \
    && make install \
    && rm -fr /opt/qmerge

# Get and install ObsPy
RUN apt-get update \
    && apt-get install -y \
        software-properties-common
RUN add-apt-repository "deb http://deb.obspy.org $(lsb_release -cs) main"
RUN wget --quiet -O - https://raw.github.com/obspy/obspy/master/misc/debian/public.key | apt-key add -
RUN apt-get update \
    && apt-get install -y \
        python3-obspy 

# Get and install PyRocko - https://pyrocko.org/docs/current/install/system/deb.html
WORKDIR /opt
RUN apt-get update \
    && apt-get install -y \
        make \
        git \
        python3-dev \
        python3-setuptools \
        python3-numpy \
        python3-numpy-dev \
        python3-scipy \
        python3-matplotlib \
        python3-pyqt4 \
        python3-pyqt4.qtopengl \
        python3-pyqt5 \
        python3-pyqt5.qtopengl \
        python3-pyqt5.qtsvg \
        python3-pyqt5.qtwebengine || apt-get install -y python3-pyqt5.qtwebkit 
RUN apt-get install -y python3-yaml \
        python3-progressbar \
        python3-jinja2 \
        python3-requests
RUN git clone https://git.pyrocko.org/pyrocko/pyrocko.git pyrocko \
    && cd pyrocko \
    && python3 setup.py install
WORKDIR /
RUN mkdir /.pyrocko/ \
    && chmod 777 /.pyrocko/

# Install Xml2Resp and scripts
WORKDIR /opt
RUN wget --no-check-certificate ${STATIONXML_CONVERTER}
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

# Create OUTPUT dir 
WORKDIR /opt
RUN mkdir /opt/OUTPUT
RUN chmod -R 777 /opt/OUTPUT

# Set entrypoint
ENTRYPOINT ["./entrypoint.sh"]
