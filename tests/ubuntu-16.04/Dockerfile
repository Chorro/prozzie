ARG BASE_DOCKER_IMAGE

FROM ${BASE_DOCKER_IMAGE} AS builder
ARG CXX
ARG INSTALL_EPEL
ARG IS_CENTOS
ARG LIBDW_DEV
ARG LIBZ_DEV
ARG LIBELF_DEV
ARG PKG_CONFIG
ARG PKG_MANAGER_INSTALL
ARG PKG_MANAGER_UPDATE

# Install epel in centos
RUN ${INSTALL_EPEL}

# Get kcov dependencies
RUN ${PKG_MANAGER_UPDATE} && ${PKG_MANAGER_INSTALL} \
	${CXX} \
	${LIBDW_DEV} \
	${LIBELF_DEV} \
	${LIBZ_DEV} \
	${PKG_CONFIG} \
	ca-certificates \
	cmake \
	curl \
	gcc \
	make \
	patch \
	python

WORKDIR /kcov
ENV KCOV_VERSION 35

# GET kcov
RUN curl -L "https://github.com/SimonKagstrom/kcov/archive/v${KCOV_VERSION}.tar.gz" | tar xz
# trick for PS4 to work
RUN sed -i "/set -x/i PS4='kcov@\${BASH_SOURCE}@\${LINENO}@'" "./kcov-${KCOV_VERSION}/src/engines/bash-helper.sh"
# Patch for not to account `fn ()` like lines in coverage
RUN [ "/bin/bash", "-c", \
	"patch <(curl -L https://github.com/SimonKagstrom/kcov/pull/258.patch)" ]
WORKDIR "/kcov/kcov-${KCOV_VERSION}/build"
RUN env CXX=g++ cmake .. && make -j 2 kcov && cp src/kcov /usr/bin/
# Centos still doesn't work well with kcov
RUN ! ${IS_CENTOS} || \
	{ echo '[[ $1 == '\''--merge'\'' ]] || { mkdir -p "$2"; exec "./$3" "${@:4}"; }' \
									> /usr/bin/kcov && chmod +x /usr/bin/kcov; }

# Obtain tclsh8.6: Centos has 8.5
WORKDIR /tcl
RUN ! ${IS_CENTOS} || { tgz=$(mktemp) && \
	curl -L -o "$tgz" \
		https://downloads.sourceforge.net/project/tcl/Tcl/8.6.8/tcl8.6.8-src.tar.gz \
		&& \
	printf '%s %s' 81656d3367af032e0ae6157eff134f89 "$tgz" | \
													   md5sum -c --status - && \
	tar xzf "$tgz" && cd tcl8.6.8/unix && \
	./configure --prefix=/usr && make && make install && cd /usr/bin && \
	ln -s tclsh8.6 tclsh; }

# Obtain tcllib: Centos tie repo's one with tcl8.5
WORKDIR /tcllib
RUN ! ${IS_CENTOS} || { tgz="$(mktemp)" && \
	curl -L -o "$tgz" \
		https://downloads.sourceforge.net/project/tcllib/tcllib/1.19/tcllib-1.19.tar.gz && \
	printf '8d3990d01e3fb66480d441d18a7a7d0d %s' "$tgz" | \
													   md5sum -c --status - && \
	tar xzf "$tgz" && cd tcllib-1.19 && \
	tclsh8.6 installer.tcl -pkg-path /usr/lib/tcllib1.19 -no-nroff -no-apps \
		-no-examples -no-wait; }

# Obtain expect: Centos' one depends on tcl8.5
WORKDIR /expect
RUN ! ${IS_CENTOS} || { tgz="$(mktemp)" && \
	curl -L -o "$tgz" \
		https://downloads.sourceforge.net/project/expect/Expect/5.45.4/expect5.45.4.tar.gz && \
	tar xzf "$tgz" && cd expect5.45.4 && ./configure --prefix=/usr && make && \
	make install; }

# Obtain shunit: Distros are outdated
RUN curl -L -o /usr/bin/shunit2 \
		https://raw.githubusercontent.com/kward/shunit2/v2.1.7/shunit2 && \
	printf '%s  %s' 4b80cbc0bfa1ac02eafc0efcb5e21510 /usr/bin/shunit2 | \
													   md5sum -c --status -

# Patch shunit to not to fail in AssertTrue
RUN sed -e '/\(failNotEquals\|failSame\) "${shunit_message_}"/ s/$/ || true/' \
	    -e '/^[[:blank:]]*shunit_match_=`expr "${shunit_condition_}" : '\''\\(\[0-9\]\*\\)'\''`$/ s/`$/ || true`/p' \
        -i /usr/bin/shunit2

WORKDIR /kafkacat
# Obtain kafkacat (Centos doesn't have in it's repos)
RUN ! ${IS_CENTOS} || { tgz=$(mktemp) && curl -L -o "$tgz" \
		https://github.com/edenhill/kafkacat/archive/1.3.1.tar.gz && \
	printf '%s  %s' 5f4bc893a80f75e5e131aee156499db7 "$tgz" | \
													md5sum -c --status - && \
	tar xzf "$tgz" && cd kafkacat-1.3.1 && \
	sed -i \
		's|^./configure|./configure --prefix=/usr|;s|--enable-json|--disable-json|;/^build libyajl/d' bootstrap.sh && \
	./bootstrap.sh; make install; }

# Obtain rkill (Centos don't have pslist)
RUN ! ${IS_CENTOS} || { curl -o /usr/bin/rkill -L \
	https://gitlab.com/pslist/pslist/raw/release/1.4.0/pslist && \
	chmod +x /usr/bin/rkill; }

# Pack everything to add to final container. DO NOT use dockerfile COPY, since
# it will not "rsync" directories, but expant it's content
WORKDIR /
RUN ["/bin/bash", "-c", "tar czf boot.tgz /usr/bin/{expect,kafkacat,kcov,rkill,shunit2,tclsh*} /usr/lib/{expect*,{lib,}tcl*} 2>&1 | grep -v 'No such file or directory'"]

#
# Actual run container
#
FROM ${BASE_DOCKER_IMAGE}
ARG IS_CENTOS
ARG KAFKACAT
ARG LIBDW
ARG PKG_MANAGER_INSTALL
ARG PKG_MANAGER_UPDATE
ARG PSLIST
ARG TCL
ARG EXPECT
ARG TCLLIB
ARG SNMPTRAP

RUN ! ${IS_CENTOS} || ${PKG_MANAGER_INSTALL} epel-release
RUN ${PKG_MANAGER_UPDATE} && ${PKG_MANAGER_INSTALL} \
	${EXPECT} \
	${KAFKACAT} \
	${SNMPTRAP} \
	${LIBDW} \
	${PSLIST} \
	${TCL} \
	${TCLLIB} \
	ca-certificates \
	make \
	rsync \
	perl \
	procps \
	socat

COPY --from=builder /boot.tgz /
RUN tar -C / -xzf /boot.tgz
