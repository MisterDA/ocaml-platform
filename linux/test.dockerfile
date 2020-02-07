FROM ubuntu:latest
RUN apt-get update && apt-get install -y curl
WORKDIR /root
ADD oplat.tar.gz .
ENV PATH=".local/bin:$PATH"
