# Build-only image
FROM koalaman/shellcheck AS shellchecki

FROM alpine:latest

# Install tools
RUN apk --no-cache add \
        curl \
        jq \
        rsync \
        && wget -O /usr/bin/y2j https://github.com/bronze1man/yaml2json/releases/download/v1.3/yaml2json_linux_amd64 \
        && chmod +x /usr/bin/y2j

COPY --from=shellchecki /bin/shellcheck /usr/bin/
