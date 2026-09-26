FROM alpine
RUN apk add --no-cache bash ca-certificates coreutils curl jq openssl python3 shadow
RUN useradd -m tunet
COPY tunet-bash.sh /usr/local/bin/tunet-bash
COPY tunet-exporter.py /usr/local/bin/tunet-exporter
ENV TUNET_MODE=exporter TUNET_KEEPALIVE_INTERVAL=120
EXPOSE 9877/tcp
USER tunet
WORKDIR /home/tunet
ENTRYPOINT ["/usr/local/bin/tunet-exporter"]
CMD []
