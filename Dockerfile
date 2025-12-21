FROM docker.io/sirrgb/dockdroid-base:latest

# User
ARG userid=1000
ARG groupid=1000

# Directories
ARG ROOT_DIR=/droid_workdir
ENV SCRIPT_DIR="${ROOT_DIR}"/scripts
ENV ROM_DIR="${ROOT_DIR}"/src/Los15
ENV KEYS_DIR="${ROOT_DIR}"/keys
ENV LOGS_DIR="${ROOT_DIR}"/logs

USER root

# Create dirs and copy scripts
RUN mkdir --parents "${SCRIPT_DIR}"
COPY scripts/ "${SCRIPT_DIR}"/
COPY py-utils/ "${BIN_DIR}"/

# Set up user and work directories
RUN chown --recursive "${userid}":"${groupid}" "${ROOT_DIR}" && chmod --recursive ug+srw "${ROOT_DIR}"

# Switch to user for execution
USER "${USER}"

# Make scripts executable
RUN chmod --recursive 500 "${SCRIPT_DIR}"

# ROM variables
ENV LOCAL_MANIFEST=''
ENV CLONE_REPOS=''
ENV DEVICE=''
ENV BUILD_TYPE=''
ENV ROM_MANIFEST=''
ENV ROM_BRANCH=''
ENV ROM_BUILD_FLAGS=''

# Fallbacks (required for non-standard naming and conflicts)
ENV LUNCH_PREFIX_FALLBACK=''
ENV ROM_PREFIX_FALLBACK=''
ENV ROM_VERSION_FALLBACK=''
ENV ROM_OTA_BRANCH_FALLBACK=''
ENV RELEASETOOL_EXTRA_FLAGS=''

# Extra variables
ENV CCACHE_SIZE=40
ENV OTA_REPO_URL=''
ENV KEYS_SUBJECT='/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
ENV TIME_ZONE='UTC'
ENV REPOPICK_PICKS=''
ENV REPOPICK_TOPICS=''
ENV REPOPICK_PULLS=''

# Authentification
ENV TELEGRAM_TOKEN=''
ENV GITHUB_TOKEN=''
ENV SF_USER=''
ENV SF_RELEASES_REPO=''
ENV SSH_USER=''
ENV SSH_UPLOAD_URL=''
ENV SSH_DOWNLOAD_URL=''

ENTRYPOINT ["/bin/bash", "-c", "${SCRIPT_DIR}/init.sh"]
