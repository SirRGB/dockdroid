FROM docker.io/bitnami/minideb:bookworm

# User
ARG userid=1000
ARG groupid=1000
ARG username=droid
ENV USER "${username}"

# Dirs
ARG ROOT_DIR=/droid_workdir
ENV SCRIPT_DIR "${ROOT_DIR}"/scripts
ENV ROM_DIR "${ROOT_DIR}"/src/Los15
ENV KEYS_DIR "${ROOT_DIR}"/keys
ENV BIN_DIR "${ROOT_DIR}"/bin
ENV LOGS_DIR "${ROOT_DIR}"/logs

# Switch to Root for Setup
USER root

# Android build dependencies
RUN install_packages \
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
    liblz4-tool \
    libncurses5 \
    libsdl1.2-dev \
    libssl-dev \
    libxml2 \
    libxml2-utils \
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
    libffi-dev \
    libbz2-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libxml2-dev \
    libxmlsec1-dev \
    liblzma-dev \
    tk-dev \
    xz-utils \
# Automation
    file \
    jq \
    unzip

# Create dirs and copy scripts
RUN mkdir -p "${SCRIPT_DIR}" "${BIN_DIR}" "${KEYS_DIR}"
COPY scripts/ "${SCRIPT_DIR}"/

# Set up user and work directories
RUN groupadd -g "${groupid}" "${username}" \
   && useradd -m -s /bin/bash -u "${userid}" -g "${groupid}" "${username}" -d "${ROOT_DIR}"
RUN chown -R "${userid}":"${groupid}" "${ROOT_DIR}" && chmod -R ug+srw "${ROOT_DIR}"

# Switch to user for execution
USER "${username}"

# Install and verify repo
RUN gpg --recv-key 8BB9AD793E8E6153AF0F9A4416530D5E920F5C65
RUN curl -o "${BIN_DIR}"/repo https://storage.googleapis.com/git-repo-downloads/repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo.asc | gpg --verify - "${BIN_DIR}"/repo

# Provide make_key to create signing keys
RUN curl https://raw.githubusercontent.com/LineageOS/android_development/refs/heads/lineage-23.0/tools/make_key > "${BIN_DIR}"/make_key

# Patch for longer key size and drop input
RUN sed -i "/read -p \"Enter password for '\$1' (blank for none\; password will be visible): \" \\\/d" "${BIN_DIR}"/make_key
RUN sed -i "s/  password/password=\"\"/g; s/echo; exit 1' EXIT INT QUIT/' EXIT/g; s/2048/4096/g" "${BIN_DIR}"/make_key

# Make scripts executable
RUN chmod -R 500 "${BIN_DIR}" "${SCRIPT_DIR}"

# ROM
ENV LOCAL_MANIFEST ""
ENV CLONE_REPOS ""
ENV DEVICE ""
ENV BUILD_TYPE ""
ENV ROM_MANIFEST ""
ENV ROM_BRANCH ""
ENV ROM_BUILD_FLAGS ""

ENV LUNCH_PREFIX_FALLBACK ""
ENV ROM_PREFIX_FALLBACK ""
ENV ROM_VERSION_FALLBACK ""
ENV ROM_OTA_BRANCH_FALLBACK ""

# Extra
ENV CCACHE_SIZE 40
ENV OTA_REPO_URL ""
ENV KEYS_SUBJECT '/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
ENV TIME_ZONE "UTC"

# Auth
ENV TELEGRAM_TOKEN ""
ENV GITHUB_TOKEN ""
ENV SF_USER ""
ENV SF_RELEASES_REPO ""

ENTRYPOINT "${SCRIPT_DIR}"/init.sh
