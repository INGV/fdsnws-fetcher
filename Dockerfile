FROM debian:stretch

LABEL maintainer="Valentino Lauciani <valentino.lauciani@ingv.it>"

ENV DEBIAN_FRONTEND=noninteractive
ENV INITRD No
ENV FAKE_CHROOT 1
ENV STATIONXML_CONVERTER=https://seiscode.iris.washington.edu/attachments/download/741/stationxml-converter-1.0.9.jar

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
	default-jre

RUN apt-get install -y \
	python-dev \
	python-pycurl \
	python-simplejson \
	libcurl4-gnutls-dev \
	libssl-dev \
    	python \
	python-psutil \
	python-requests \
	python-jsonschema \
    	python-setuptools \
	python-dev \
	build-essential \
    	libxml2-dev \
	libxslt1-dev \
	libz-dev

# pip
#WORKDIR /tmp
#RUN easy_install pip

# 
# Python libraries + util & tornado
#RUN pip install --upgrade pip \
#    simplejson httplib2 defusedxml lxml queuelib dweepy \
#    tornado 

# port
#EXPOSE 8888

# Set .bashrc
RUN echo "" >> /root/.bashrc \
     && echo "##################################" >> /root/.bashrc \
     && echo "alias ll='ls -l --color'" >> /root/.bashrc \
     && echo "" >> /root/.bashrc \
     && echo "export LC_ALL=\"C\"" >> /root/.bashrc \
     && echo "" >> /root/.bashrc

# Set 'root' pwd
RUN echo root:toor | chpasswd

# Copy GIT deploy key
RUN mkdir /root/.ssh
COPY id_rsa* known_hosts /root/.ssh/
RUN chmod 600 /root/.ssh/id_rsa \
    && chmod 644 /root/.ssh/id_rsa.pub \
    && chmod 644 /root/.ssh/known_hosts \
    && chmod 700 /root/.ssh/

# Get and install rdseed
WORKDIR /opt
RUN wget http://ds.iris.edu/pub/programs/rdseedv5.3.1.tar.gz \
    && tar xvzf rdseedv5.3.1.tar.gz \
    && rm /opt/rdseedv5.3.1.tar.gz \
    && cd /usr/bin \
    && ln -s /opt/rdseedv5.3.1/rdseed.rh6.linux_64 rdseed

# Install Xml2Resp
WORKDIR /opt
RUN wget --no-check-certificate ${STATIONXML_CONVERTER}
COPY 01_find_stations.sh /opt/
COPY 02_get_dless-resp.sh /opt/
COPY 03_get_dataselect_list-mseed-sac.sh /opt/
COPY entrypoint.sh /opt/
COPY config.sh /opt/
COPY stationxml.conf /opt/
RUN chmod 755 /opt/01_find_stations.sh
RUN chmod 755 /opt/02_get_dless-resp.sh
RUN chmod 755 /opt/03_get_dataselect_list-mseed-sac.sh

# Install service
WORKDIR /opt
#COPY ads_services.py /opt/
#RUN chmod 755 /opt/ads_services.py
RUN mkdir /opt/OUTPUT

ENTRYPOINT ["./entrypoint.sh"]
