ARG PREFIX=/opt/OCamlPlatform
ARG OPAM_REPOSITORY='git://github.com/MisterDA/opam-repository.git#ocaml-platform'
ARG OCAML_VERSION=4.10.0
ARG OPAM_VERSION=master
ARG OPAM_MONOREPO_VERSION=master

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
ARG OPAM_REPOSITORY
ARG OCAML_VERSION
ARG OPAM_MONOREPO_VERSION
WORKDIR "$PREFIX"
RUN opam init -v -y -a --disable-sandboxing \
        -c "ocaml-base-compiler.${OCAML_VERSION}" \
        "$OPAM_REPOSITORY"
RUN opam exec -- opam install -v -y --with-doc \
        $(opam list --required-by ocaml-platform --columns=package -s) \
        ocaml-platform
RUN opam exec -- opam clean -cars

WORKDIR /home/user
ADD --chown=user:user https://github.com/ocamllabs/opam-monorepo/archive/OPAM_MONOREPO_VERSION.tar.gz opam-monorepo-$OPAM_MONOREPO_VERSION.tar.gz
RUN tar xf "opam-monorepo-${OPAM_MONOREPO_VERSION}.tar.gz"
WORKDIR "opam-monorepo-${OPAM_MONOREPO_VERSION}"
RUN opam exec -- dune build @install
RUN cp _build/install/default/bin/opam-monorepo "${PREFIX}/bin"

FROM ocaml-platform-builder AS ocaml-platform-tester
ARG PREFIX
ARG OPAM_REPOSITORY
ARG OCAML_VERSION
WORKDIR "$PREFIX"
RUN opam init -v -y -a --disable-sandboxing \
        -c "ocaml-base-compiler.${OCAML_VERSION}" \
        "$OPAM_REPOSITORY"
RUN opam exec -- opam install -y odoc && \
    opam exec -- opam install -v -y --with-test \
        $(opam list --required-by ocaml-platform --columns=package -s) \
        ocaml-platform
