FROM paperist/texlive-ja AS base
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y wget xz-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PANDOC_VERSION 3.1.9
ENV PANDOC_DOWNLOAD_URL https://hackage.haskell.org/package/pandoc-$PANDOC_VERSION/pandoc-$PANDOC_VERSION.tar.gz
ENV PANDOC_ROOT /usr/local/pandoc
ENV PATH $PATH:$PANDOC_ROOT/bin

# download and install pandoc
ENV PANDOC_DEB_URL https://github.com/jgm/pandoc/releases/download/3.1.9/pandoc-3.1.9-1-amd64.deb
ENV PANDOCCR_TAR_URL https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.17.0/pandoc-crossref-Linux.tar.xz

WORKDIR /install-tmp
RUN wget $PANDOC_DEB_URL && \
    dpkg -i pandoc-3.1.9-1-amd64.deb && \
    wget $PANDOCCR_TAR_URL && \
    ls -l pandoc-crossref-Linux.tar.xz && \
    echo ${PWD} && \
    tar -Jxvf pandoc-crossref-Linux.tar.xz && \
    mv pandoc-crossref /usr/local/bin

# process for TeX
RUN kanji-config-updmap-sys ipaex && \
    tlmgr install \
      collection-langjapanese \
      lm \
      lm-math \
      lualatex-math \
      selnolig

COPY scripts/ /usr/local/bin/
COPY crossref_config.yaml /config/crossref_config.yaml
COPY listings-setup.tex /config/listings-setup.tex

VOLUME /workdir
WORKDIR /workdir
USER pandoc
