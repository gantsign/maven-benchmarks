#!/usr/bin/env bash

set -e

mkdir -p tmp/bin

dependencies=(
"https://github.com/oracle/graal/releases/download/vm-1.0.0-rc15/\
graalvm-ce-1.0.0-rc15-linux-amd64.tar.gz"

"https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/\
jdk8u202-b08/OpenJDK8U-jdk_x64_linux_hotspot_8u202b08.tar.gz"

"https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/\
jdk8u202-b08_openj9-0.12.1/OpenJDK8U-jdk_x64_linux_openj9_8u202b08_openj9-0.12.1.tar.gz"

"https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.2%2B9/\
OpenJDK11U-jdk_x64_linux_hotspot_11.0.2_9.tar.gz"

"https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/\
jdk-11.0.2%2B9_openj9-0.12.1/OpenJDK11U-jdk_x64_linux_openj9_11.0.2_9_openj9-0.12.1_openj9-0.12.1.tar.gz"

"http://mirror.ox.ac.uk/sites/rsync.apache.org/maven/maven-3/3.6.0/binaries/\
apache-maven-3.6.0-bin.tar.gz"
)

prepare() {
  for i in "${dependencies[@]}"
  do
      (set -x; wget --no-clobber "$i")
  done

  (set -x; tar --extract \
    --transform 's|graalvm-ce-1.0.0-rc15|jdk/8u202_graalvm|' --file \
    'graalvm-ce-1.0.0-rc15-linux-amd64.tar.gz')

  (set -x; tar --extract \
    --transform 's|jdk8u202-b08|jdk/8u202|' --file \
    'OpenJDK8U-jdk_x64_linux_hotspot_8u202b08.tar.gz')

  (set -x; tar --extract \
    --transform 's|jdk8u202-b08|jdk/8u202_openj9|' --file \
    'OpenJDK8U-jdk_x64_linux_openj9_8u202b08_openj9-0.12.1.tar.gz')

  (set -x; tar --extract \
    --transform 's|jdk-11.0.2+9|jdk/11.0.2|' --file \
    'OpenJDK11U-jdk_x64_linux_hotspot_11.0.2_9.tar.gz')

  (set -x; tar --extract \
    --transform 's|jdk-11.0.2+9_openj9-0.12.1|jdk/11.0.2_openj9|' --file \
    'OpenJDK11U-jdk_x64_linux_openj9_11.0.2_9_openj9-0.12.1_openj9-0.12.1.tar.gz')

  (set -x; tar --extract \
    --transform 's|apache-maven-3.6.0|maven/3.6.0|' --file \
    'apache-maven-3.6.0-bin.tar.gz')

  (set -x; rm -rf commons-collections)

  # Checkout a specific commit because the latest release doesn't contain a
  # Java 11 fix.
  (set -x; git clone --shallow-since=2019-03-24 \
    'https://github.com/apache/commons-collections.git')
  (cd commons-collections && set -x; \
    git checkout 68948279bc8d54ed5f54ea84243a9182d868e016)

  GRAAL_HOME="$PWD/jdk/8u202_graalvm"

  (set -x; "$GRAAL_HOME/bin/javac" \
    -classpath "$GRAAL_HOME/lib/tools.jar" ../Javac.java)

  (set -x; "$GRAAL_HOME/bin/native-image" --no-server \
    "-H:ConfigurationFileDirectories=$PWD/../config" \
    -H:-MultiThreaded \
    -H:+NativeArchitecture \
    -H:Name=javac-native "-H:Path=$PWD/bin" \
    -cp "..:$GRAAL_HOME/lib/tools.jar" \
    Javac)
}

(cd tmp && prepare)
