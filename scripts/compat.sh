#!/bin/bash

# Initialize PyEnv
_setup_pyenv() {
  curl -fsSL https://pyenv.run | bash
  export PYENV_ROOT="${HOME}"/.pyenv
  [[ -d "${PYENV_ROOT}"/bin ]] && export PATH="${PYENV_ROOT}"/bin:"${PATH}"
  eval "$(pyenv init - bash)"
  "${SHELL}"
}

# Set up PyEnv with Python 2.7
_init_py2() {
  _setup_pyenv
  pyenv install 2
  pyenv global 2
}

# Set up PyEnv with Python 3.11
_init_py3() {
  _setup_pyenv
  pyenv install 3.11
  pyenv global 3.11
}

# Set up Temurin 8 and re-enable TLS 1/1.1
_setup_jdk8() {
  local jdk_dir jdk_tag jdk_name
  jdk_dir="${HOME}"/java/jdk
  jdk_tag=jdk8u472-b08
  jdk_name=OpenJDK8U-jdk_x64_linux_hotspot_"$(echo ${jdk_tag//jdk/} | tr -d -)".tar.gz
  mkdir -p "${jdk_dir}"
  curl -fsSOL https://github.com/adoptium/temurin8-binaries/releases/download/"${jdk_tag}"/"${jdk_name}" --output-dir "${jdk_dir}"
  echo 55963261b4df76f76109eaa442b8e9621425a4a45c69fd5507bb33899dffd7d5 "${jdk_dir}"/"${jdk_name}" | sha256sum --check
  tar xvf "${jdk_dir}"/"${jdk_name}" --directory="${jdk_dir}"
  rm "${jdk_dir}"/"${jdk_name}"

  export JAVA_HOME="${jdk_dir}"/"${jdk_tag}"
  export PATH="${JAVA_HOME}"/bin:"${PATH}"

  sed -i 's/TLSv1, TLSv1.1, //g' "${JAVA_HOME}"/jre/lib/security/java.security
  export ANDROID_JACK_VM_ARGS='-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G'
  export LC_ALL=C
}

# Allow greater key sizes
_key_size_sys_core() {
  sed -i 's/!= 2048/< 2048/' "${ROM_DIR}"/system/core/libmincrypt/tools/DumpPublicKey.java
}

_key_size_recovery() {
  sed -i 's/!= 2048/< 2048/' "${ROM_DIR}"/bootable/recovery/tools/dumpkey/DumpPublicKey.java
}


# A7-9
if [[ "${ANDROID_VERSION}" -lt 10 ]]; then
  _init_py2
# A10-15
else
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
