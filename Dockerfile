FROM golang:1.19-alpine AS builder

ENV CGO_ENABLED=0

RUN \
 echo "**** install build dependencies ****" && \
 apk update && apk add --no-cache git make

RUN \
 echo "**** build go application ****" && \
 git clone https://github.com/LINKIWI/dotproxy.git && \
 cd dotproxy && go mod tidy && go get golang.org/x/tools/cmd/stringer && make && sed -i 's/127\.0\.0\.1\:/0\.0\.0\.0\:/g' /go/dotproxy/config.example.yaml

FROM antilax3/alpine

RUN \
echo "**** install runtime packages ****" && \
apk add --no-cache \
    libcap

# copy executable and config
COPY --from=builder /go/dotproxy/bin/dotproxy-linux-amd64 /app/dotproxy
COPY --from=builder /go/dotproxy/config.example.yaml /defaults/config.yaml

# set version label
ARG build_date
ARG version
LABEL build_date=$build_date
LABEL version=$version
LABEL maintainer="Nightah"

# set working directory
WORKDIR /app

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 53 53/udp
VOLUME /config
