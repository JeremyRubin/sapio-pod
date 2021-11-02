FROM node:lts-bullseye-slim

RUN apt-get update && apt-get install -y gconf-service \
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
wget \
git \
llvm \
build-essential \
libtool autotools-dev automake pkg-config bsdmainutils python3 \
libevent-dev libboost-dev libboost-system-dev libboost-filesystem-dev libboost-test-dev \
libdb-dev libdb++-dev libsqlite3-dev \
gcc && rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/sh ubitcoin
USER ubitcoin
WORKDIR /home/ubitcoin

RUN git clone --depth 1 https://github.com/JeremyRubin/bitcoin.git -b checktemplateverify-rebase-4-15-21 \
&& cp bitcoin/share/rpcauth/rpcauth.py  . \
&& cd bitcoin && ./autogen.sh && ./configure --with-incompatible-bdb --without-gui && make -j 4 && cp src/bitcoind /home/ubitcoin/bitcoind \
&& cd .. && rm -rf bitcoin

USER root
RUN useradd -ms /bin/sh app
USER app
WORKDIR /home/app
ENV RUSTUP_HOME=/home/app/local/rustup \
    CARGO_HOME=/home/app/local/cargo \
    PATH=/home/app/local/cargo/bin:$PATH \
    RUST_VERSION=nightly-2021-08-01

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
    rustc --version;

RUN git clone https://github.com/sapio-lang/sapio
WORKDIR /home/app/sapio
RUN cargo fetch
RUN RUSTFLAGS="-Zgcc-ld=lld" cargo build --release --bin sapio-cli
RUN cp target/release/sapio-cli /home/app/
RUN rm -rf /home/app/sapio
WORKDIR /home/app/
RUN git clone --depth=1 https://github.com/sapio-lang/sapio-studio
WORKDIR /home/app/sapio-studio
RUN yarn install --no-cache && yarn cache clean
RUN yarn build
RUN yarn build-electron
USER ubitcoin
WORKDIR /home/ubitcoin/.bitcoin
COPY bitcoin.conf .
USER root
WORKDIR /home/root
COPY ./runner.sh .
CMD sh runner.sh
