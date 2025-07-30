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
}

# Set up JDK8 and re-enable TLS 1/1.1
_setup_jdk8() {
  local jdk_dir jdk_tag jdk_name
  jdk_dir="${HOME}"/java/jdk
  jdk_tag=jdk8u462-b08
  jdk_name=OpenJDK8U-jdk_x64_linux_hotspot_"$(echo ${jdk_tag//jdk/} | tr -d -)".tar.gz
  mkdir -p "${jdk_dir}"
  curl -fsSOL https://github.com/adoptium/temurin8-binaries/releases/download/"${jdk_tag}"/"${jdk_name}" --output-dir "${jdk_dir}"
  echo 5d64ae542b59a962b3caadadd346f4b1c3010879a28bb02d928326993de16e79 "${jdk_dir}"/"${jdk_name}" | sha256sum --check
  tar xvf "${jdk_dir}"/"${jdk_name}" --directory="${jdk_dir}"
  rm "${jdk_dir}"/"${jdk_name}"

  export JAVA_HOME="${jdk_dir}"/"${jdk_tag}"
  export PATH="${JAVA_HOME}"/bin:"${PATH}"

  sed -i 's/TLSv1, TLSv1.1, //g' "${JAVA_HOME}"/jre/lib/security/java.security
  export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"
  export LC_ALL=C
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
