ARG PREFIX=/opt/ocaml-platform
ARG OPAM_REPO='git://github.com/MisterDA/opam-repository.git#ocaml-platform'


FROM debian:10 AS ocaml-platform-builder-base
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


FROM ocaml-platform-builder-base AS ocaml-platform-builder
ARG PREFIX
ARG OCAML_VERSION=4.10.0
ARG OPAM_VERSION=master

RUN useradd --create-home --shell /bin/sh user
RUN mkdir -p "$PREFIX" && chown -R user:user "$PREFIX"
WORKDIR /home/user
USER user

ADD --chown=user:user https://github.com/ocaml/ocaml/archive/$OCAML_VERSION.tar.gz ocaml-$OCAML_VERSION.tar.gz
RUN tar xf ocaml-$OCAML_VERSION.tar.gz && \
    cd ocaml-$OCAML_VERSION && \
    ./configure --prefix="$PREFIX" && \
    make -j$(nproc) world.opt V=1 && \
    make install

ADD --chown=user:user https://github.com/ocaml/opam/archive/$OPAM_VERSION.zip opam-$OPAM_VERSION.zip
RUN unzip opam-$OPAM_VERSION.zip && \
    cd opam-$OPAM_VERSION && \
    ./configure --prefix="$PREFIX" && \
    make lib-ext all -j1 DUNE_ARGS='--verbose' V=1 && \
    make -j1 && \
    make install


# FIXME: add depext once the interface for Opam 2.1.0 is finalized

FROM ocaml-platform-builder AS ocaml-platform
ARG PREFIX
ARG OPAM_REPO
ARG DUNIVERSE_VERSION=master
RUN  cd "$PREFIX" && \
     opam init -a --disable-sandboxing -y "$OPAM_REPO" && \
     eval $(opam env) && \
     opam install -y --with-doc \
         $(opam list --required-by ocaml-platform --columns=package -s) \
         ocaml-platform

ADD --chown=user:user https://github.com/ocamllabs/duniverse/archive/$DUNIVERSE_VERSION.zip duniverse-$DUNIVERSE_VERSION.zip
RUN unzip duniverse-$DUNIVERSE_VERSION.zip && \
    cd duniverse-$DUNIVERSE_VERSION && \
    eval $(opam env) && \
    make && \
    make install PREFIX="$PREFIX"/bin


FROM ocaml-platform-builder AS ocaml-platform-tester
ARG PREFIX
ARG OPAM_REPO
RUN  cd "$PREFIX" && \
     opam init -a --disable-sandboxing -y $OPAM_REPO && \
     eval $(opam env) && \
     opam install -y --with-test \
         $(opam list --required-by ocaml-platform --columns=package -s) \
         ocaml-platform
