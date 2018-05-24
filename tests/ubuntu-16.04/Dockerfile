FROM ubuntu:16.04 AS builder

# Get kcov dependencies
RUN apt update && apt install --no-install-recommends -y \
	ca-certificates \
	cmake \
	curl \
	g++ \
	libdw-dev \
	libz-dev \
	make \
	pkg-config \
	python

WORKDIR /kcov
ENV KCOV_VERSION 35

# GET kcov
RUN curl -L "https://github.com/SimonKagstrom/kcov/archive/v${KCOV_VERSION}.tar.gz" | tar xz
# trick for PS4 to work
RUN sed -i "/set -x/i PS4='kcov@\${BASH_SOURCE}@\${LINENO}@'" "./kcov-${KCOV_VERSION}/src/engines/bash-helper.sh"
RUN mkdir -p "kcov-${KCOV_VERSION}/build"
WORKDIR "/kcov/kcov-${KCOV_VERSION}/build"
RUN cmake ..
RUN make -j 2 kcov

#
# Actual run container
#
FROM ubuntu:16.04

RUN apt update && apt install --no-install-recommends -y \
	kafkacat \
	libdw1 \
	make \
	pslist \
	shunit2 \
	socat

COPY --from=builder /kcov/kcov-35/build/src/kcov /usr/local/bin/kcov
