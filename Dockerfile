FROM paperist/alpine-texlive-ja AS base

ENV BUILD_DEPS \
    alpine-sdk \
    cabal \
    coreutils \
    ghc \
    libffi \
    musl-dev \
    zlib-dev
ENV PERSISTENT_DEPS \
    gmp \
    graphviz \
    sed

ENV PANDOC_VERSION 2.14.0.3
ENV PANDOC_DOWNLOAD_URL https://hackage.haskell.org/package/pandoc-$PANDOC_VERSION/pandoc-$PANDOC_VERSION.tar.gz
ENV PANDOC_ROOT /usr/local/pandoc
ENV PATH $PATH:$PANDOC_ROOT/bin

# install and build packages
RUN apk upgrade --update && \
    apk add --virtual .build-deps $BUILD_DEPS && \
    apk add --virtual .persistent-deps $PERSISTENT_DEPS
RUN mkdir -p /pandoc-build && \
    cd /pandoc-build && \
    curl -fsSL "$PANDOC_DOWNLOAD_URL" | tar -xzf - && \
    cd pandoc-$PANDOC_VERSION && \
    cabal update && \
    cabal install --only-dependencies && \
    cabal configure --prefix=$PANDOC_ROOT && \
    cabal build && \
    cabal install && \
    rm -Rf /pandoc-build \
           $PANDOC_ROOT/lib \
           /root/.cabal \
           /root/.ghc && \
   set -x && \
   addgroup -g 1000 -S pandoc && \
   adduser -u 1000 -D -S -G pandoc pandoc && \
   apk del .build-deps

RUN kanji-config-updmap-sys ipaex

COPY scripts/ /usr/local/bin/
COPY crossref_config.yaml /config/crossref_config.yaml
COPY listings-setup.tex /config/listings-setup.tex

VOLUME /workdir
WORKDIR /workdir
USER pandoc
