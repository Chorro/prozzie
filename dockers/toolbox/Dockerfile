# Build-only image
FROM mitchty/alpine-ghc:latest AS builder

WORKDIR /opt/shellcheck

RUN apk add --no-cache build-base git

ARG SHELLCHECK_VERSION=v0.6.0

RUN git clone https://github.com/koalaman/shellcheck.git . --branch ${SHELLCHECK_VERSION}\
	&& cabal update \
	&& cabal install --dependencies-only --ghc-options="-optlo-Os -split-sections" \
	&& cabal build Paths_ShellCheck \
	&& ghc -optl-static -optl-pthread -isrc -idist/build/autogen --make shellcheck -split-sections -optc-Wl,--gc-sections -optlo-Os \
	&& strip --strip-all shellcheck

FROM alpine:latest

# Install tools
RUN apk --no-cache add \
        curl \
        jq \
        rsync \
        && wget -O /usr/bin/y2j https://github.com/bronze1man/yaml2json/releases/download/v1.3/yaml2json_linux_amd64 \
        && chmod +x /usr/bin/y2j

COPY --from=builder /opt/shellcheck /usr/bin/
