FROM node:lts-bullseye-slim as bitcoin_layer

RUN apt-get update && apt-get install -y wget \
git \
build-essential \
libtool autotools-dev automake pkg-config bsdmainutils python3  gcc curl && rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash ubitcoin
USER ubitcoin
WORKDIR /home/ubitcoin

RUN set -eux; git clone --depth 1 https://github.com/JeremyRubin/bitcoin.git -b checktemplateverify-rebase-4-15-21-WORK \
&& cp bitcoin/share/rpcauth/rpcauth.py  . \
&& cd bitcoin \
&& cd depends \
&& make HOST=$(gcc -dumpmachine) NO_QT=1\
&& cd .. \
&& ./autogen.sh \
&& CONFIG_SITE=$PWD/depends/$(gcc -dumpmachine)/share/config.site ./configure \
--with-incompatible-bdb --without-gui --prefix=$HOME --disable-tests --disable-bench --with-libs=no \
--enable-reduce-exports LDFLAGS=-static-libstdc++ \
&& make -j $(nproc) && make install \
&& cd .. && rm -rf bitcoin

# Clear Bitcoin Setup
FROM node:16-bullseye-slim


RUN apt-get update && apt-get install -y wget \
git \
build-essential

USER root
RUN useradd -ms /bin/bash app

RUN apt-get update && apt-get install -y llvm clang && rm -rf /var/lib/apt/lists/*
USER app
WORKDIR /home/app
ENV RUSTUP_HOME=/home/app/local/rustup \
    CARGO_HOME=/home/app/local/cargo \
    PATH=/home/app/local/cargo/bin:$PATH \
    RUST_VERSION=nightly-2023-05-01

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='3dc5ef50861ee18657f9db2eeb7392f9c2a6c95c90ab41e45ab4ca71476b4338' ;; \
        armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='67777ac3bc17277102f2ed73fd5f14c51f4ca5963adadf7f174adf4ebc38747b' ;; \
        arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='32a1532f7cef072a667bac53f1a5542c99666c4071af0c9549795bbdb2069ec1' ;; \
        i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='e50d1deb99048bc5782a0200aa33e4eea70747d49dffdc9d06812fd22a372515' ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.24.3/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version; \
    rustup target add wasm32-unknown-unknown
RUN set -eux; \
    git clone --depth=1 https://github.com/sapio-lang/sapio -b pod-fbdcfc0b1944e163eead7c9fbf24cb3289f230ec; \
    cd sapio; \
    cargo fetch; \
    RUSTFLAGS="-Zgcc-ld=lld" cargo build --release --bin sapio-cli; \
    cp target/release/sapio-cli /home/app/; \
    cd /home/app/sapio/plugin-example; \
    cargo build --target wasm32-unknown-unknown
# Don't delete -- keep!
# RUN rm -rf /home/app/sapio
WORKDIR /home/app/
RUN set -eux; git clone --depth=1 https://github.com/sapio-lang/sapio-studio -b pod-9f4934640b5a1f82b0f43611ad83abbec3645998; \
cd /home/app/sapio-studio; \
yarn install; \
yarn add serve; \
yarn cache clean; \
yarn build; \
yarn build-electron
USER ubitcoin
WORKDIR /home/ubitcoin/.bitcoin
COPY bitcoin.conf .
USER root
WORKDIR /home/root
COPY ./runner.sh .

# Files required for Electron runtime
# And some general dev experience improvements
RUN apt-get update && apt-get install -y \
gconf-service \
libasound2 \
libatk1.0-0 \
libc6 \
libcairo2 \
libcups2 \
libdbus-1-3 \
libexpat1 \
libfontconfig1 \
libgbm-dev \
libgcc1 \
libgconf-2-4 \
libgdk-pixbuf2.0-0 \
libglib2.0-0 \
libgtk-3-0 \
libnspr4 \
libpango-1.0-0 \
libpangocairo-1.0-0 \
libstdc++6 \
libx11-6 \
libx11-xcb1 \
libxcb1 \
libxcomposite1 \
libxcursor1 \
libxdamage1 \
libxext6 \
libxfixes3 \
libxi6 \
libxrandr2 \
libxrender1 \
libxss1 \
libxtst6 \
ca-certificates \
fonts-liberation \
libnss3 \
lsb-release \
xdg-utils \
neovim procps && rm -rf /var/lib/apt/lists/*


# Copy Bitcoin Files
RUN useradd -ms /bin/bash ubitcoin
USER ubitcoin
COPY --from=bitcoin_layer /home/ubitcoin /home/ubitcoin


# Main Entry Point
USER root
RUN chmod +x runner.sh
RUN chmod +x /bin/bash
RUN chmod +x /bin/sh
ENTRYPOINT ["/bin/sh", "-c"]
CMD ./runner.sh
