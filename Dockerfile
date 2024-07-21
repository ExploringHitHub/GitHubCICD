# FROM: https://github.com/nodejs/docker-node/blob/master/14/buster-slim/Dockerfile
FROM node:14.15-buster-slim

ARG GIT_VERSION='v2.32.0'
ARG PMD_VERSION='6.36.0'
ARG SFDX_VERSION='@7.109.0'

ENV PMD_VERSION=$PMD_VERSION

SHELL [ "/bin/bash", "-c" ]

RUN cd /root && \
    apt-get update && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends \
        jq \
        gettext-base \
        software-properties-common \
        wget \
        curl \
        unzip \
        gawk \
        gnupg \
        python \
        libcurl3-gnutls \
        libio-tee-perl \
        # these utils are only to compile git, to be removed. Buster has too old git in it's repo.
        make \
        libssl-dev \
        libghc-zlib-dev \
        libcurl4-gnutls-dev \
        libexpat1-dev \
        gettext \
        && \
    wget -q https://github.com/git/git/archive/${GIT_VERSION}.zip -O git.zip  && \
    unzip git.zip && \
    cd git-* && \
    make prefix=/usr/local all && \
    make prefix=/usr/local install && \
    cd .. && \
    rm -r git* && \
    git config --global user.name "Not Configured" && \
    git config --global user.email "user@example.com" && \
    echo "[INFO] installing openjdk for pmd ..." &&\
    wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - && \
    add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ && \
    apt-get update && \
    mkdir -p /usr/share/man/man1 && \
    apt-get install -y --no-install-recommends adoptopenjdk-8-hotspot-jre && \
    echo "[INFO] installing sfdx-cli ..." &&\
    npm install sfdx-cli${SFDX_VERSION} --global && \
    wget -q https://github.com/pmd/pmd/releases/download/pmd_releases%2F${PMD_VERSION}/pmd-bin-${PMD_VERSION}.zip -O pmd.zip && \
    mkdir /pmd && \
    unzip pmd.zip && \
    cd pmd-bin* && \
    mv bin lib /pmd && \
    cd .. && \
    rm -r /root/*  && \
    apt-get remove -y \
        software-properties-common \
        make \
        libssl-dev \
        libghc-zlib-dev \
        libcurl4-gnutls-dev \
        libexpat1-dev \
        gettext && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives /root/.cache /root/.npm /usr/local/share/locale/* && \
    echo "[INFO] installing SFDX-Git-Delta plugin - https://github.com/scolladon/sfdx-git-delta" &&\
    echo "[INFO] node > 14.6.0 is required for it." &&\
    echo y | sfdx plugins:install sfdx-git-delta && \
    echo "[INFO] installing sfpowerkit plugin - https://github.com/Accenture/sfpowerkit" &&\
    echo y | sfdx plugins:install sfpowerkit && \
    # ============ all done ==============
    echo "perl version: $(perl --version | head -2 )"  && \
    git --version && \
    echo "node version: $(node --version)" && \
    echo "npm version: $(npm --version)" && \
    sfdx --version && \
    sfdx plugins && \
    python --version && \
    java -version && \
    echo "PMD VERSION: $PMD_VERSION" && \
    echo "BASH_VERSION: $BASH_VERSION"

RUN echo "[INFO] applying workaround for not being able to override /bin/sh as a default shell in gitlab - https://gitlab.com/gitlab-org/gitlab-runner/-/issues/1170" && \
    echo "dash dash/sh boolean false" | debconf-set-selections && \
    rm /bin/sh && \
    ln -s /bin/bash /bin/sh && \
    ls -l /bin/sh
ENTRYPOINT [ "/bin/bash", "-c" ]
CMD ["bash"]
