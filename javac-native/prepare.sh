#!/usr/bin/env bash

set -e

mkdir -p tmp/bin

dependencies=(
"https://github.com/graalvm/graalvm-ce-builds/releases/download/\
vm-19.3.1/graalvm-ce-java8-linux-amd64-19.3.1.tar.gz"

"https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/\
jdk8u242-b08/OpenJDK8U-jdk_x64_linux_hotspot_8u242b08.tar.gz"

"https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/\
jdk8u242-b08_openj9-0.18.1/OpenJDK8U-jdk_x64_linux_openj9_8u242b08_openj9-0.18.1.tar.gz"

"https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/\
jdk-11.0.6%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.6_10.tar.gz"

"https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/\
jdk-11.0.6%2B10_openj9-0.18.1/OpenJDK11U-jdk_x64_linux_openj9_11.0.6_10_openj9-0.18.1.tar.gz"

"http://mirror.ox.ac.uk/sites/rsync.apache.org/maven/maven-3/\
3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz"
)

prepare() {
  for i in "${dependencies[@]}"
  do
      (set -x; wget --no-clobber "$i")
  done

  (set -x; tar --extract \
    --transform 's|graalvm-ce-java8-19.3.1|jdk/8u242_graalvm-ce|' --file \
    'graalvm-ce-java8-linux-amd64-19.3.1.tar.gz')

  (set -x; tar --extract \
    --transform 's|jdk8u242-b08|jdk/8u242|' --file \
    'OpenJDK8U-jdk_x64_linux_hotspot_8u242b08.tar.gz')

  (set -x; tar --extract \
    --transform 's|jdk8u242-b08|jdk/8u242_openj9|' --file \
    'OpenJDK8U-jdk_x64_linux_openj9_8u242b08_openj9-0.18.1.tar.gz')

  (set -x; tar --extract \
    --transform 's|jdk-11.0.6+10|jdk/11.0.6|' --file \
    'OpenJDK11U-jdk_x64_linux_hotspot_11.0.6_10.tar.gz')

  (set -x; tar --extract \
    --transform 's|jdk-11.0.6+10|jdk/11.0.6_openj9|' --file \
    'OpenJDK11U-jdk_x64_linux_openj9_11.0.6_10_openj9-0.18.1.tar.gz')

  (set -x; tar --extract \
    --transform 's|apache-maven-3.6.3|maven/3.6.3|' --file \
    'apache-maven-3.6.3-bin.tar.gz')

  (set -x; rm -rf commons-collections)

  # Checkout a specific commit because the latest release doesn't contain a
  # Java 11 fix.
  (set -x; git clone --shallow-since=2019-03-24 \
    'https://github.com/apache/commons-collections.git')
  (cd commons-collections && set -x; \
    git checkout 68948279bc8d54ed5f54ea84243a9182d868e016)

  # These tests cause intermittent failures on OpenJ9: java.lang.OutOfMemoryError: Java heap space
  rm commons-collections/src/test/java/org/apache/commons/collections4/map/ReferenceIdentityMapTest.java
  rm commons-collections/src/test/java/org/apache/commons/collections4/map/ReferenceMapTest.java

  export GRAAL_HOME="$PWD/jdk/8u242_graalvm-ce"

  (set -x; "$GRAAL_HOME/bin/javac" \
    -classpath "$GRAAL_HOME/lib/tools.jar" ../Javac.java)

  (set -x; "$GRAAL_HOME/bin/gu" install native-image)

  (set -x; "$GRAAL_HOME/bin/native-image" --no-server \
    -H:IncludeResourceBundles=com.sun.tools.javac.resources.compiler,com.sun.tools.javac.resources.javac \
    --no-fallback \
    -H:+NativeArchitecture \
    -H:Name=javac-native "-H:Path=$PWD/bin" \
    -cp "..:$GRAAL_HOME/lib/tools.jar" \
    Javac)
}

(cd tmp && prepare)
