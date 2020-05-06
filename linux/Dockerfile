ARG PREFIX=/opt/ocaml-platform
ARG OPAM_REPO='git://github.com/MisterDA/opam-repository.git#ocaml-platform'
ARG OCAML_VERSION=master
ARG OPAM_VERSION=4.10.0

FROM debian:10 AS ocaml-platform-builder-base
ARG PREFIX
RUN apt-get update && apt-get install -y \
        bubblewrap \
        build-essential \
        curl \
        git \
        m4 \
        unzip
ENV OPAMROOT=$PREFIX/opam
ENV PATH=$PREFIX/bin:$PATH


FROM ocaml-platform-builder-base AS ocaml-platform-builder
ARG PREFIX
ARG OCAML_VERSION
ARG OPAM_VERSION

RUN useradd --create-home --shell /bin/sh user
RUN mkdir -p "$PREFIX" && chown -R user:user "$PREFIX"
WORKDIR /home/user
USER user

ADD --chown=user:user https://github.com/ocaml/opam/archive/$OPAM_VERSION.tar.gz opam-$OPAM_VERSION.tar.gz
RUN tar xf "opam-${OPAM_VERSION}.tar.gz"
WORKDIR "opam-${OPAM_VERSION}"
RUN make cold CONFIGURE_ARGS="--prefix '$PREFIX'"
RUN make cold-install -j$(nproc) V=1


FROM ocaml-platform-builder AS ocaml-platform
ARG PREFIX
ARG OPAM_REPO
ARG OCAML_VERSION
WORKDIR "$PREFIX"
RUN opam init -v -y -a --disable-sandboxing \
        -c "ocaml-base-compiler.${OCAML_VERSION}" \
        "$OPAM_REPO"
RUN opam exec -- opam install -v -y --with-doc \
        $(opam list --required-by ocaml-platform --columns=package -s) \
        ocaml-platform


FROM ocaml-platform-builder AS ocaml-platform-tester
ARG PREFIX
ARG OPAM_REPO
ARG OCAML_VERSION
WORKDIR "$PREFIX"
RUN opam init -v -y -a --disable-sandboxing \
        -c "ocaml-base-compiler.${OCAML_VERSION}" \
        "$OPAM_REPO"
RUN opam exec -- opam install -v -y --with-test \
        $(opam list --required-by ocaml-platform --columns=package -s) \
        ocaml-platform
