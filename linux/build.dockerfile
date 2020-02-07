FROM ubuntu:latest
RUN apt-get update && apt-get install -y build-essential curl git m4 unzip rsync
WORKDIR /root
ARG OPAM_VERSION=2.0.6
ADD https://github.com/ocaml/opam/releases/download/$OPAM_VERSION/opam-$OPAM_VERSION-x86_64-linux opam
RUN chmod +x ./opam && ./opam init --disable-sandboxing
RUN eval $(./opam env) && ./opam install -y depext
COPY packages packages
RUN eval $(./opam env) && export PATH=".:$PATH" && opam depext -i --yes $(cat packages)
RUN mkdir -p .local/bin && mv opam .local/bin
