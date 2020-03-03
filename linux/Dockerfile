ARG PREFIX=/opt/ocaml-platform
ARG OPAM_REPO='git://github.com/MisterDA/opam-repository.git#ocaml-platform'

FROM ocaml/opam2:4.10 AS builder
ARG PREFIX
ARG OCAML_VERSION=4.10.0
ARG OPAM_VERSION=2.0.6
ARG DUNIVERSE_VERSION=depext
ARG DUNE_VERSION=2.3.1

USER root
RUN apt-get install -y m4
RUN mkdir -p "$PREFIX" && chown -R opam:opam "$PREFIX"
USER opam
RUN opam install dune
WORKDIR /home/opam

ADD --chown=opam:opam https://github.com/ocamllabs/duniverse/archive/$DUNIVERSE_VERSION.zip duniverse.zip
RUN unzip duniverse.zip && \
        cd duniverse-$DUNIVERSE_VERSION && \
        eval $(opam env) && \
        make && \
        make install PREFIX="$PREFIX"/bin

ADD --chown=opam:opam https://github.com/ocaml/opam/releases/download/$OPAM_VERSION/opam-full-$OPAM_VERSION.tar.gz opam-full.tar.gz
RUN tar xf opam-full.tar.gz && \
        cd opam-full-$OPAM_VERSION && \
        eval $(opam env) && \
        opam install --deps-only . && \
        ./configure --prefix="$PREFIX" && \
        make -j1 OCAMLC='ocamlc -unsafe-string' OCAMLOPT='ocamlopt -unsafe-string' && \
        make install

ADD --chown=opam:opam https://github.com/ocaml/dune/archive/$DUNE_VERSION.tar.gz dune.tar.gz
RUN tar xf dune.tar.gz && \
        cd dune-$DUNE_VERSION && \
        eval $(opam env) && \
        make release && \
        make install PREFIX="$PREFIX"

ADD --chown=opam:opam https://github.com/ocaml/ocaml/archive/$OCAML_VERSION.tar.gz ocaml.tar.gz
RUN tar xf ocaml.tar.gz && \
        cd ocaml-$OCAML_VERSION && \
        ./configure --prefix="$PREFIX" && \
        make -j$(nproc) world.opt && \
        make install

FROM debian:10 AS opam_base
ARG PREFIX
RUN apt-get update && apt-get install -y \
        bubblewrap \
        build-essential \
        curl \
        git \
        m4 \
        unzip \
        rsync
ENV OPAMROOT=$PREFIX/opam
ENV PATH=$PREFIX/bin:$PATH

FROM opam_base AS opam_setup
ARG PREFIX
ARG OPAM_REPO
COPY --from=builder "$PREFIX" "$PREFIX"/
RUN  cd "$PREFIX" && \
        opam init -a --disable-sandboxing -y $OPAM_REPO && \
        eval $(opam env) && \
        opam install -y depext && \
        opam depext -y ocaml-platform && \
        opam install -y ocaml-platform

FROM opam_base AS tester_setup
ARG PREFIX
COPY --from=opam_setup "$PREFIX" "$PREFIX"/
WORKDIR project
RUN echo '(executable (name hello_world) (libraries lwt.unix))' >> dune && \
        echo 'Lwt_main.run (Lwt_io.printf "Hello, world!\n")' >> hello_world.ml

FROM tester_setup AS opam_tester
RUN eval $(opam env) && \
        dune build && \
        ./_build/default/hello_world.exe

FROM tester_setup AS duniverse_tester
ARG OPAM_REPO
COPY ocaml-platform-hello-world.opam .
RUN duniverse init --opam-repo "$OPAM_REPO" && \
        duniverse pull && \
        eval $(opam env) && \
        dune build && \
        ./_build/default/hello_world.exe
