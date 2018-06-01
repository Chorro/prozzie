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
	patch \
	pkg-config \
	python \
	shunit2

WORKDIR /kcov
ENV KCOV_VERSION 35

# GET kcov
RUN curl -L "https://github.com/SimonKagstrom/kcov/archive/v${KCOV_VERSION}.tar.gz" | tar xz
# trick for PS4 to work
RUN sed -i "/set -x/i PS4='kcov@\${BASH_SOURCE}@\${LINENO}@'" "./kcov-${KCOV_VERSION}/src/engines/bash-helper.sh"
# Patch for not to account `fn ()` like lines in coverage
RUN [ "/bin/bash", "-c", \
	"patch <(curl -L https://github.com/SimonKagstrom/kcov/pull/258.patch)" ]
RUN mkdir -p "kcov-${KCOV_VERSION}/build"
WORKDIR "/kcov/kcov-${KCOV_VERSION}/build"
RUN cmake ..
RUN make -j 2 kcov

# Patch shunit to not to fail in AssertTrue
RUN [ "/bin/bash", "-c", \
	"set -o pipefail && patch=$(mktemp) && \
    curl -L https://storage.googleapis.com/google-code-attachments/shunit2/issue-37/comment-1/assertTrue_assertFalse_error.patch \
        >\"$patch\" && \
    md5sum -c --status <(printf '%s  %s' '65f8947f5f43c577f110db915c7801d6' \"$patch\") && \
    patch -d /usr/bin < \"$patch\" && \
    rm -f \"$patch\"" ]

#
# Actual run container
#
FROM ubuntu:16.04

RUN apt update && env DEBIAN_FRONTEND=noninteractive \
	apt install --no-install-recommends -y \
	expect \
	kafkacat \
	libdw1 \
	make \
	pslist \
	shunit2 \
	socat \
	tcl8.6 \
	tcllib

COPY --from=builder /kcov/kcov-35/build/src/kcov /usr/local/bin/kcov
COPY --from=builder /usr/bin/shunit2 /usr/bin/
