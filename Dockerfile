FROM alpine
RUN apk add --no-cache bash ca-certificates shadow curl openssl
RUN useradd -m tunet
COPY tunet-bash.sh /usr/local/bin/tunet-bash
USER tunet
WORKDIR /home/tunet
ENTRYPOINT ["/usr/local/bin/tunet-bash"]
CMD ["--help"]
