FROM ubuntu:latest
RUN apt-get update && apt-get install -y \
        build-essential \
        curl \
        git \
        m4 \
        rsync \
        unzip
ARG OCAML_VERSION=4.09.0
ARG OCAML_PATH=4.09.0
ARG OPAM_VERSION=2.0.6
ENV MAKEFLAGS=-j$(nproc)
WORKDIR /root
ADD https://github.com/ocaml/ocaml/archive/$OCAML_VERSION.tar.gz $OCAML_VERSION.tar.gz
RUN tar xf $OCAML_VERSION.tar.gz
WORKDIR ocaml-$OCAML_PATH
RUN ./configure
RUN make world.opt
RUN make install
WORKDIR /root
ADD https://github.com/ocaml/opam/releases/download/$OPAM_VERSION/opam-full-$OPAM_VERSION.tar.gz opam-full-$OPAM_VERSION.tar.gz
RUN tar xf opam-full-$OPAM_VERSION.tar.gz
WORKDIR opam-full-$OPAM_VERSION
RUN ./configure --prefix=/root/.local && \
        make lib-ext all -j1 OCAMLC='ocamlc -unsafe-string' OCAMLOPT='ocamlopt -unsafe-string' && \
        make install
WORKDIR /root
ENV PATH=/root/.local/bin:$PATH OPAMYES=true
RUN opam init -a --disable-sandboxing
RUN eval $(opam env) && \
        opam switch create user ocaml-base-compiler.$OCAML_VERSION && \
        opam switch remove default
COPY ocaml-platform.opam ocaml-platform.opam
COPY packages packages
RUN eval $(opam env) && opam install depext
RUN eval $(opam env) && opam depext -i $(cat packages)
# RUN eval $(opam env) && opam install --deps-only ./ocaml-platform.opam
