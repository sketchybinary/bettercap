# build stage
FROM node:latest as build-ui
RUN git clone https://github.com/bettercap/ui.git && \
    cd ui && \
    npm audit fix && \
    npm i && \
    npm run ng build --prod

# build go
FROM golang:alpine AS build-env

ENV SRC_DIR $GOPATH/src/github.com/bettercap/bettercap

RUN apk add --update ca-certificates
RUN apk add --no-cache --update bash iptables wireless-tools build-base libpcap-dev libusb-dev linux-headers libnetfilter_queue-dev git

WORKDIR $SRC_DIR
ADD . $SRC_DIR
RUN go get -u github.com/golang/dep/...
RUN make deps
RUN make

# get caplets
RUN mkdir -p /usr/local/share/bettercap
RUN git clone https://github.com/bettercap/caplets /usr/local/share/bettercap/caplets

# final stage
FROM alpine
RUN apk add --update ca-certificates
RUN apk add --no-cache --update bash iproute2 libpcap libusb-dev libnetfilter_queue wireless-tools
COPY --from=build-env /go/src/github.com/bettercap/bettercap/bettercap /app/
COPY --from=build-env /go/src/github.com/bettercap/bettercap/caplets /app/
COPY --from=build-ui /ui/dist/ui/ /usr/local/share/bettercap/ui/
WORKDIR /app

EXPOSE 80 443 53 5300 8080 8081 8082 8083 8000
ENTRYPOINT ["/app/bettercap"]
