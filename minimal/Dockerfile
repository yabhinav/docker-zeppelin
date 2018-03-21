###########################################################################
# Dockerfile for building Zepplin on Debian Stable Minimal Image        ###
#                                                                       ###
# Author  : Abhinav Y <https://yabhinav.github.io>                      ###
# Version : 0.7.3 #Indicates the Zeppelin Version                       ###
###########################################################################

# Pull Latest Debian Stable Minimal Server
FROM debian:stable
MAINTAINER  yabhinav <yabhinav.github.com>

# Default Zeppelin Version can be overriden during docker build
# docker build all/ --build-arg Z_VERSION=0.7.3 -t yabhinav/zeppelin:minimal
ARG Z_VERSION="0.7.3"
ARG LOG_TAG="[ZEPPELIN_${Z_VERSION}]:"

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8
#ENV LC_ALL en_US.UTF-8

WORKDIR /tmp

######## Installing DEPENDENCIES  #########
RUN echo "$LOG_TAG : Install dependency packages" && \
    apt-get update && apt-get install -y --no-install-recommends \
		build-essential sudo vim curl less openssh-server wget vim iputils-ping telnet dnsutils bzip2 ntp \
  && sleep 1 \
  && rm -rf /var/lib/apt/list/*

##########################################
# OpenJDK Java 1.8
# Installing distribution-provided OpenJDK
##########################################
# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home
# do some fancy footwork to create a JAVA_HOME that's cross-architecture-safe
RUN ln -svT "/usr/lib/jvm/java-8-openjdk-$(dpkg --print-architecture)" /docker-java-home
ENV JAVA_HOME /docker-java-home
ENV JAVA_VERSION 8u162
ENV JAVA_DEBIAN_VERSION 8u162-b12-1~deb9u1
ENV CA_CERTIFICATES_JAVA_VERSION 20170531+nmu1
RUN set -ex; \
	\
# deal with slim variants not having man page directories (which causes "update-alternatives" to fail)
	if [ ! -d /usr/share/man/man1 ]; then \
		mkdir -p /usr/share/man/man1; \
	fi; \
	\
	apt-get update; \
	apt-get install -y \
		openjdk-8-jdk-headless="$JAVA_DEBIAN_VERSION" \
		ca-certificates-java="$CA_CERTIFICATES_JAVA_VERSION" \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
# verify that "docker-java-home" returns what we expect
	[ "$(readlink -f "$JAVA_HOME")" = "$(docker-java-home)" ]; \
	\
# update-alternatives so that future installs of other OpenJDK versions don't change /usr/bin/java
	update-alternatives --get-selections | awk -v home="$(readlink -f "$JAVA_HOME")" 'index($3, home) == 1 { $2 = "manual"; print | "update-alternatives --set-selections" }'; \
# ... and verify that it actually worked for one of the alternatives we care about
	update-alternatives --query java | grep -q 'Status: manual'
# see CA_CERTIFICATES_JAVA_VERSION notes above
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

##########################################
#   Install Python Dependencies
##########################################
# should install conda first before numpy, matploylib since pip and python will be installed by conda
RUN echo "$LOG_TAG : Install miniconda2 related packages" && \
    apt-get -y update && \
    apt-get install -y bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion && \
    echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda2-4.3.11-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh
ENV PATH /opt/conda/bin:$PATH

RUN echo "$LOG_TAG : Install python related packages" && \
    apt-get -y update && \
    apt-get install -y python-dev python-pip && \
    apt-get install -y gfortran && \
    # numerical/algebra packages
    apt-get install -y libblas-dev libatlas-dev liblapack-dev && \
    # font, image for matplotlib
    apt-get install -y libpng-dev libfreetype6-dev libxft-dev && \
    # for tkinter
    apt-get install -y python-tk libxml2-dev libxslt-dev zlib1g-dev && \
    conda install -y numpy pandas matplotlib seaborn scipy py4j scikit-learn

##########################################
#     Zeppelin
##########################################
ENV ZEPPELIN_VERSION ${Z_VERSION}
ENV ZEPPELIN_HOME /opt/zeppelin
ENV ZEPPELIN_DATA /zeppelin
ENV ZEPPELIN_LOG_DIR ${ZEPPELIN_DATA}/log
ENV ZEPPELIN_PID_DIR ${ZEPPELIN_DATA}/run
ENV ZEPPELIN_NOTEBOOK_DIR ${ZEPPELIN_DATA}/notebook
# ENV SPARK_HOME  ${ZEPPELIN_HOME}/

# Zeppelin User - Which is defualt login user
RUN groupadd -r --gid 501 zeppelin \
  && useradd -r --uid 501 --home-dir ${ZEPPELIN_HOME} --create-home -g zeppelin zeppelin
# Setting the PATH environment variable globally and for the Zeppelin user
ENV PATH=$PATH:$JAVA_HOME/bin:$ZEPPELIN_HOME/bin
RUN echo "PATH=$PATH:$JAVA_HOME/bin:$ZEPPELIN_HOME/bin" >> ~/.bashrc

# Prepare the permission for the mount points
RUN mkdir -p ${ZEPPELIN_DATA} && chown zeppelin:zeppelin ${ZEPPELIN_DATA}
VOLUME ${ZEPPELIN_DATA}
# Let temporary directories to be volumes as well
VOLUME /tmp

USER zeppelin
WORKDIR ${ZEPPELIN_HOME}

RUN set -xe \
  && cd /tmp \
  && wget -q http://www.apache.org/dist/zeppelin/zeppelin-${Z_VERSION}/zeppelin-${Z_VERSION}-bin-netinst.tgz \
  && tar -zxvf zeppelin-${Z_VERSION}-bin-netinst.tgz -C ${ZEPPELIN_HOME} --strip-components=1 \
  && rm *.tgz

##########################################
# Install Interpreter Dependencies(R)
##########################################
USER root
RUN set -xe \
  && apt-get update \
  && apt-get install -y r-base r-base-dev r-recommended r-cran-knitr r-cran-caret r-cran-data.table r-cran-glmnet \
  && chmod a+wx /usr/local/lib/R/site-library || true \
  && sleep 1 \
  && rm -rf /var/lib/apt/list/*
USER zeppelin

##########################################
# Install all Interpreter(s)
##########################################
# We don't need that much memory for interpreter installation
RUN set -xe \
  && mkdir -p ${ZEPPELIN_LOG_DIR} \
  && export ZEPPELIN_MEM='-Xmx256m' \
  && install-interpreter.sh --list && install-interpreter.sh --name angular,python,shell,bigquery,file,jdbc,kylin,livy,md,postgresql,cassandra,elasticsearch

##########################################
# Exposing Zeppelin and Spark Port(s)
# Need run -p to expose to host(localhost)
##########################################
# 8080 is for zeppelin web UI
ENV ZEPPELIN_PORT 8080
EXPOSE 8080
# 4040 is for spark UI
EXPOSE 4040

##########################################
# Cleanup
##########################################
USER root
RUN echo "$LOG_TAG : Cleanup" && \
    apt-get autoclean && \
    apt-get clean && \
    rm -rf /tmp/*

USER zeppelin
WORKDIR ${ZEPPELIN_DATA}

ENTRYPOINT ${ZEPPELIN_HOME}/bin/zeppelin.sh && /bin/bash
#CMD ["${ZEPPELIN_HOME}/bin/zeppelin.sh"]
