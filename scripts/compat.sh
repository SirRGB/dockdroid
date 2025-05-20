#!/bin/bash

# Set up Py2
_setup_py2() {
  curl -fsSL https://pyenv.run | bash
  export PYENV_ROOT="${HOME}"/.pyenv
  [[ -d "${PYENV_ROOT}"/bin ]] && export PATH="${PYENV_ROOT}"/bin:"${PATH}"
  eval "$(pyenv init - bash)"
  "${SHELL}"

  pyenv install 2
  pyenv global 2
  python --version
}

# Set up JDK8 and re-enable TLS 1/1.1
_setup_jdk8() {
  local jdk_dir jdk_name
  jdk_dir="${HOME}"/java/jdk
  jdk_name=OpenJDK8U-jdk_x64_linux_hotspot_8u452b09.tar.gz
  mkdir -p "${jdk_dir}"
  curl -fsSOL https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u452-b09/OpenJDK8U-jdk_x64_linux_hotspot_8u452b09.tar.gz --output-dir "${jdk_dir}"
  echo 9448308a21841960a591b47927cf2d44fdc4c0533a5f8111a4b243a6bafb5d27 "${jdk_dir}"/"${jdk_name}" | sha256sum --check
  tar xvf "${jdk_dir}"/"${jdk_name}" --directory="${jdk_dir}"
  rm "${jdk_dir}"/"${jdk_name}"

  export JAVA_HOME="${jdk_dir}"/jdk8u452-b09
  export PATH="${JAVA_HOME}"/bin:"${PATH}"

  sed -i 's/TLSv1, TLSv1.1, //g' "${JAVA_HOME}"/jre/lib/security/java.security
  export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"
  export LC_ALL=C

  java -version
  javac -version
}

# Allow greater key sizes
_key_size_sys_core() {
  sed -i 's/!= 2048/< 2048/' "${ROM_DIR}"/system/core/libmincrypt/tools/DumpPublicKey.java
}

_key_size_recovery() {
  sed -i 's/!= 2048/< 2048/' "${ROM_DIR}"/bootable/recovery/tools/dumpkey/DumpPublicKey.java
}

_setup_py2
if [[ "${ANDROID_VERSION}" -lt 9 ]]; then
  _setup_jdk8
fi

if [[ "${ANDROID_VERSION}" -gt 7 ]]; then
  _key_size_recovery
else
  _key_size_sys_core
fi
