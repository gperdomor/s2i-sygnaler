# swift-ubuntu16.04
FROM computersciencehouse/s2i-base-ubuntu:16.04

# Put the maintainer name in the image metadata
MAINTAINER Gustavo Perdomo <gperdomor@gmail.com>

# Swift version that this image provides
ENV SWIFT_VERSION 3.0

# Set labels used in OpenShift to describe the builder image
LABEL io.k8s.description="Platform for building Sygnaler Push Gateway" \
      io.k8s.display-name="Swift 3.0" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="swift,3.0"

# Add the PPA key and install required packages
RUN export DEBIAN_FRONTEND=noninteractive && \
wget -qO- http://dev.iachieved.it/iachievedit.gpg.key | apt-key add - && \
echo "deb http://iachievedit-repos.s3.amazonaws.com/ xenial main" >> /etc/apt/sources.list && \
apt-get -yq update && \
apt-get -yq install swift-3.0 && \
export PATH=/opt/swift/swift-3.0/usr/bin:$PATH

# Install MySQLProvider deps
RUN apt-get -yq install libmysqlclient20 libmysqlclient-dev

# Installing Curl and HTTP2 Support
RUN apt-get -y -qq build-dep curl && \
    apt-get -y -qq install git g++ make binutils autoconf automake autotools-dev \
    libtool pkg-config zlib1g-dev libcunit1-dev libssl-dev libxml2-dev libev-dev \
    libevent-dev libjansson-dev libjemalloc-dev cython python3-dev python-setuptools

RUN cd ~ && \
    git clone --quiet https://github.com/nghttp2/nghttp2.git && \
    cd nghttp2 && \
    git submodule update --init && \
    autoreconf -i && \
    automake && \
    autoconf && \
    ./configure && \
    make && \
    make install

RUN cd ~ && \
    wget -q http://curl.haxx.se/download/curl-7.52.1.tar.bz2 && \
    tar -xjf curl-7.52.1.tar.bz2 && \
    cd curl-7.52.1 && \
    ./configure --with-nghttp2=/usr/local --with-ssl && \
    make && \
    make install && \
    ldconfig && \
    ln -fs /usr/local/bin/curl /usr/bin/curl

# Clean APT cache
RUN apt-get -yq clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy the S2I scripts to /usr/libexec/s2i, since the base image sets
# io.openshift.s2i.scripts-url label that way
COPY ./.s2i/bin/ /usr/libexec/s2i

# Link /usr/bin/env to /bin/env
RUN mkdir -p /bin && \
ln -s /usr/bin/env /bin/env

# Chown /opt/app-root to the deployment user and drop privileges
RUN chown -R 1001:0 /opt/app-root && chmod -R og+rwx /opt/app-root
USER 1001

# Set the default port for applications built using this image
EXPOSE 8080

# Set the default CMD for the image
CMD ["/usr/libexec/s2i/usage"]

