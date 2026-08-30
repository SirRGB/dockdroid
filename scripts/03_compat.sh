#!/bin/bash

# Initialize PyEnv
_setup_pyenv() {
  eval "$(pyenv init - bash)"
}

# Set up PyEnv with Python 2.7
_init_py2() {
  _setup_pyenv
  pyenv global 2
}

# Set up PyEnv with Python 3.11
_init_py3() {
  _setup_pyenv
  pyenv global 3.11
  pip3 install requests
}

# Set up Temurin 8 and re-enable TLS 1/1.1
_setup_jdk8() {
  local jdk_dir jdk_tag jdk_name
  jdk_dir="${HOME}"/java/jdk
  jdk_tag=$("${SCRIPT_DIR}"/03_fetch_temurin_tag.py)
  jdk_name=OpenJDK8U-jdk_x64_linux_hotspot_$(tr --delete '-' <<< "${jdk_tag//jdk/}").tar.gz
  mkdir --parents "${jdk_dir}"
  curl_cmd --remote-name https://github.com/adoptium/temurin8-binaries/releases/download/"${jdk_tag}"/"${jdk_name}" --output-dir "${jdk_dir}"
  curl_cmd https://github.com/adoptium/temurin8-binaries/releases/download/"${jdk_tag}"/"${jdk_name}".sha256.txt | sed "s|${jdk_name}|${jdk_dir}/${jdk_name}|g" | sha256sum --check
  tar --extract --verbose --file="${jdk_dir}"/"${jdk_name}" --directory="${jdk_dir}"
  rm "${jdk_dir}"/"${jdk_name}"

  export JAVA_HOME="${jdk_dir}"/"${jdk_tag}"
  export PATH="${JAVA_HOME}"/bin:"${PATH}"

  sed --in-place 's/TLSv1, TLSv1.1, //g' "${JAVA_HOME}"/jre/lib/security/java.security
  export ANDROID_JACK_VM_ARGS='-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G'
  export LC_ALL=C
}

# Allow greater key sizes
_key_size_sys_core() {
  sed --in-place 's/!= 2048/< 2048/' "${ROM_DIR}"/system/core/libmincrypt/tools/DumpPublicKey.java
}

_key_size_recovery() {
  sed --in-place 's/!= 2048/< 2048/' "${ROM_DIR}"/bootable/recovery/tools/dumpkey/DumpPublicKey.java
}


# A7-9
if [[ "${ANDROID_VERSION}" -lt 10 ]]; then
  _init_py2
# A10-15
elif [[ "${ANDROID_VERSION}" -lt 16 ]]; then
  _init_py3
fi

# A7/A8
if [[ "${ANDROID_VERSION}" -lt 9 ]]; then
  _setup_jdk8
fi

# A8/9
if [[ "${ANDROID_VERSION}" -gt 7 ]] && [[ "${ANDROID_VERSION}" -lt 10 ]]; then
  _key_size_recovery
# A7
elif [[ "${ANDROID_VERSION}" -lt 8 ]]; then
  _key_size_sys_core
fi
