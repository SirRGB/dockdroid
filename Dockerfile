FROM bitnami/minideb:bookworm

# User
ARG userid=1000
ARG groupid=1000
ARG username=droid

# ROM
ENV LOCAL_MANIFEST https://raw.githubusercontent.com/SirRGB/local_manifests/refs/heads/main/cheeseburgerdumpling/A14Lineage.xml
ENV DEVICE cheeseburger
ENV BUILD_TYPE userdebug
ENV ROM_MANIFEST https://github.com/LineageOS/android
ENV ROM_BRANCH lineage-21.0
ENV KEYS_SUBJECT '/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'

# Extra
ENV CCACHE_SIZE 80
ENV OTA_REPO_URL git@github.com:SirRGB/ota_config

# Dirs
ENV ROOT_DIR /droid_workdir
ENV SCRIPT_DIR "${ROOT_DIR}"/scripts
ENV SRC_SUBDIR Los14
ENV ROM_DIR "${ROOT_DIR}"/src/"${SRC_SUBDIR}"
ENV OTA_DIR "${ROM_DIR}"_ota
ENV KEYS_DIR "${ROOT_DIR}"/keys
ENV BIN_DIR "${ROOT_DIR}"/bin
ENV SECRETS_DIR "${ROOT_DIR}"/secrets
ENV LOGS_DIR "${ROOT_DIR}"/logs

# Switch to Root for Setup
USER root

# Android build deps
RUN install_packages bc bison build-essential ca-certificates ccache curl flex g++-multilib gcc-multilib git git-lfs gnupg \
    gperf imagemagick lib32readline-dev lib32z1-dev libelf-dev liblz4-tool libsdl1.2-dev libssl-dev libxml2 libxml2-utils \
    lzop pngcrush python3 python-is-python3 rsync schedtool ssh squashfs-tools unzip xsltproc zip zlib1g-dev

# Create dirs and copy scripts
RUN mkdir -p "${SCRIPT_DIR}" "${ROM_DIR}" "${BIN_DIR}" "${SECRETS_DIR}" "${KEYS_DIR}"
COPY scripts/ "${SCRIPT_DIR}"/
COPY bin/ "${BIN_DIR}"/

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
RUN curl https://raw.githubusercontent.com/LineageOS/android_development/refs/heads/lineage-22.1/tools/make_key > "${BIN_DIR}"/make_key
# Patch for longer key size and drop input
RUN sed -i "s/2048/4096/g" "${BIN_DIR}"/make_key
RUN sed -i "s/read -p \"Enter password for '\$1' (blank for none\; password will be visible): \" \\\//g" "${BIN_DIR}"/make_key
RUN sed -i "s/  password/password=\"\"/g; s/echo; exit 1' EXIT INT QUIT/' EXIT/g" "${BIN_DIR}"/make_key
# Install Telegram script
RUN curl https://raw.githubusercontent.com/fabianonline/telegram.sh/refs/heads/master/telegram > "${BIN_DIR}"/telegram
RUN chmod -R 500 "${BIN_DIR}" "${SCRIPT_DIR}"

ENTRYPOINT "${SCRIPT_DIR}"/init.sh
