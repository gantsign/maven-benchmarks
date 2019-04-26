#!/usr/bin/env bash

set -e

mkdir -p tmp

dependencies=(
"https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/\
jdk8u212-b03/OpenJDK8U-jdk_x64_linux_hotspot_8u212b03.tar.gz"

"https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/\
jdk8u212-b03_openj9-0.14.0/OpenJDK8U-jdk_x64_linux_openj9_8u212b03_openj9-0.14.0.tar.gz"

"https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/\
jdk-11.0.3%2B7/OpenJDK11U-jdk_x64_linux_hotspot_11.0.3_7.tar.gz"

"https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/\
jdk-11.0.3%2B7_openj9-0.14.0/OpenJDK11U-jdk_x64_linux_openj9_11.0.3_7_openj9-0.14.0.tar.gz"

"http://mirror.ox.ac.uk/sites/rsync.apache.org/maven/maven-3/3.6.1/binaries/\
apache-maven-3.6.1-bin.tar.gz"
)

prepare() {
  for i in "${dependencies[@]}"
  do
      (set -x; wget --no-clobber "$i")
  done

  (set -x; tar --extract \
    --transform 's|jdk8u212-b03|jdk/8u212|' --file \
    'OpenJDK8U-jdk_x64_linux_hotspot_8u212b03.tar.gz')

  (set -x; tar --extract \
    --transform 's|jdk8u212-b03|jdk/8u212_openj9|' --file \
    'OpenJDK8U-jdk_x64_linux_openj9_8u212b03_openj9-0.14.0.tar.gz')

  (set -x; tar --extract \
    --transform 's|jdk-11.0.3+7|jdk/11.0.3|' --file \
    'OpenJDK11U-jdk_x64_linux_hotspot_11.0.3_7.tar.gz')

  (set -x; tar --extract \
    --transform 's|jdk-11.0.3+7|jdk/11.0.3_openj9|' --file \
    'OpenJDK11U-jdk_x64_linux_openj9_11.0.3_7_openj9-0.14.0.tar.gz')

  (set -x; tar --extract \
    --transform 's|apache-maven-3.6.1|maven/3.6.1|' --file \
    'apache-maven-3.6.1-bin.tar.gz')

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
}

(cd tmp && prepare)
