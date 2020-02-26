FROM ubuntu:latest
RUN apt-get update && apt-get install -y \
        bubblewrap \
        build-essential \
        curl \
        git \
        m4 \
        rsync \
        unzip
RUN groupadd -r user && useradd --no-log-init -m -g user user
USER user
WORKDIR /home/user
COPY --chown=user:user installer.sh ./
COPY --chown=user:user dist/ocaml-platform-x86_64-linux.tar.gz /mnt/
RUN ./installer.sh file:///mnt/ocaml-platform-x86_64-linux.tar.gz
