FROM paperist/alpine-texlive-ja AS base

ENV BUILD_DEPS \
    alpine-sdk \
    cabal \
    coreutils \
    ghc \
    libffi \
    musl-dev \
    lua5.3-dev \
    zlib-dev
ENV PERSISTENT_DEPS \
    gmp \
    libffi \
    lua5.3 \
    lua5.3-lpeg \
    sed

ENV PANDOC_VERSION 2.14.0.3
ENV PANDOC_DOWNLOAD_URL https://hackage.haskell.org/package/pandoc-$PANDOC_VERSION/pandoc-$PANDOC_VERSION.tar.gz
ENV PANDOC_ROOT /usr/local/pandoc
ENV PATH $PATH:$PANDOC_ROOT/bin

# install and build packages
RUN apk upgrade --update && \
    apk add --virtual .build-deps $BUILD_DEPS && \
    apk add --virtual .persistent-deps $PERSISTENT_DEPS

# build pandoc
RUN mkdir -p /pandoc-build && \
    cd /pandoc-build && \
    curl -fsSL "$PANDOC_DOWNLOAD_URL" | tar -xzf - && \
    cd pandoc-$PANDOC_VERSION && \
    cabal new-update && \
    cabal install --only-dependencies && \
    cabal configure --prefix=$PANDOC_ROOT && \
    cabal new-build \
       --disable-tests \
       --jobs  \
       .
RUN cd /pandoc-build/pandoc-$PANDOC_VERSION && \
    mkdir -p $PANDOC_ROOT/bin && \
    cabal install \
      --installdir=$PANDOC_ROOT/bin \
      --install-method=copy

# build pandoc-crossref
ENV PANDOCCR_VERSION 0.3.12.0
ENV PANDOCCR_DOWNLOAD_URL https://github.com/lierdakil/pandoc-crossref/archive/refs/tags/v$PANDOCCR_VERSION.tar.gz
RUN cd /pandoc-build && \
    curl -fsSL "$PANDOCCR_DOWNLOAD_URL" | tar -xzf - && \
    cd pandoc-crossref-$PANDOCCR_VERSION && \
    cabal install --only-dependencies && \
    cabal configure --prefix=$PANDOC_ROOT && \
    cabal new-build \
      --jobs . && \
    cabal install \
      --installdir=$PANDOC_ROOT/bin \
      --install-method=copy

# final process
RUN rm -Rf /pandoc-build \
       $PANDOC_ROOT/lib \
       /root/.cabal \
       /root/.ghc && \
   set -x && \
   addgroup -g 1000 -S pandoc && \
   adduser -u 1000 -D -S -G pandoc pandoc && \
   apk del .build-deps

# process for TeX
RUN kanji-config-updmap-sys ipaex && \
    tlmgr install \
      collection-langjapanese \
      lm \ 
      lm-math 

COPY scripts/ /usr/local/bin/
COPY crossref_config.yaml /config/crossref_config.yaml
COPY listings-setup.tex /config/listings-setup.tex

VOLUME /workdir
WORKDIR /workdir
USER pandoc
