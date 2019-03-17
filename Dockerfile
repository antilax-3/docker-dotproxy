FROM golang:alpine AS builder

RUN \
 echo "**** install build dependencies ****" && \
 apk update && apk add --no-cache git make && \
 go get -u -v golang.org/x/lint/golint golang.org/x/tools/cmd/stringer

RUN \
 echo "**** build go application ****" && \
 git clone https://github.com/LINKIWI/dotproxy.git && \
 cd dotproxy && make && sed -i 's/localhost\:/0\.0\.0\.0\:/g' /go/dotproxy/config.example.yaml

FROM antilax3/alpine

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
EXPOSE 7012 7012/udp
VOLUME /config