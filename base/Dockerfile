FROM docker.io/debian:trixie-slim

# User
ARG userid=1000
ARG groupid=1000
ENV USER=droid

# Switch to Root for Setup
USER root

# Directories
ARG ROOT_DIR=/droid_workdir
ENV BIN_DIR="${ROOT_DIR}"/bin

# Android build dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
    bc \
    bison \
    build-essential \
    ca-certificates \
    ccache \
    curl \
    flex \
    g++-multilib \
    gcc-multilib \
    git \
    git-lfs \
    gnupg \
    gperf \
    imagemagick \
    lib32readline-dev \
    lib32z1-dev \
    libelf-dev \
    libncurses6 \
    libsdl1.2-dev \
    libssl-dev \
    libxml2 \
    libxml2-utils \
    lz4 \
    lzop \
    pngcrush \
    python3 \
    python-is-python3 \
    rsync \
    schedtool \
    ssh \
    squashfs-tools \
    xsltproc \
    zip \
    zlib1g-dev \
# Python
    libbz2-dev \
    liblzma-dev \
    libsqlite3-dev \
    libreadline-dev \
# Automation
    file \
    unzip

RUN rm --recursive /var/lib/apt/lists /var/cache/apt/archives

# Symlink libncurses for compatibility
RUN ln --symbolic /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
RUN ln --symbolic /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5

# Create dirs and copy scripts
RUN mkdir --parents "${BIN_DIR}"

# Set up user and work directories
RUN groupadd --gid "${groupid}" "${USER}" \
   && useradd --create-home --shell /bin/bash --uid "${userid}" --gid "${groupid}" "${USER}" --home-dir "${ROOT_DIR}"
RUN chown --recursive "${userid}":"${groupid}" "${ROOT_DIR}" && chmod --recursive ug+srw "${ROOT_DIR}"

# Switch to user for execution
USER "${USER}"

# Curl flags
RUN echo '/usr/bin/curl --fail --silent --show-error --location "$@"' > "${BIN_DIR}"/curl_cmd

# Make scripts executable
RUN chmod --recursive 700 "${BIN_DIR}"
ENV PYENV_ROOT="${ROOT_DIR}"/pyenv-master
ENV PATH="${PYENV_ROOT}"/bin:"${BIN_DIR}":"${PATH}"

# Install and verify repo
RUN gpg --recv-key 8BB9AD793E8E6153AF0F9A4416530D5E920F5C65
RUN curl_cmd https://storage.googleapis.com/git-repo-downloads/repo --output "${BIN_DIR}"/repo
RUN curl_cmd https://storage.googleapis.com/git-repo-downloads/repo.asc | gpg --verify - "${BIN_DIR}"/repo

# Provide make_key to create signing keys
RUN curl_cmd https://raw.githubusercontent.com/LineageOS/android_development/refs/heads/lineage-23.2/tools/make_key --output "${BIN_DIR}"/make_key

# Patch for longer key size and drop input
RUN sed --in-place "/read -p \"Enter password for '\$1' (blank for none\; password will be visible): \" \\\/d" "${BIN_DIR}"/make_key
RUN sed --in-place "s/  password/password=\"\"/g; s/echo; exit 1' EXIT INT QUIT/' EXIT/g; s/2048/4096/g" "${BIN_DIR}"/make_key

# PyEnv
RUN curl_cmd --remote-name https://github.com/pyenv/pyenv/archive/refs/heads/master.zip --output-dir /tmp
RUN unzip /tmp/master.zip -d "${ROOT_DIR}"/
RUN rm /tmp/*
RUN pyenv install 2 3.11
