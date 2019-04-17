#!/usr/bin/env bash

set -e

base_path="$(pwd)/tmp/maven/3.6.0/bin:$PATH"

results_file="$(pwd)/results.csv"

benchmark() {
    test_name="$1"

    export JAVA_HOME="$(pwd)/tmp/jdk/$jdk_name"
    export PATH="$JAVA_HOME/bin:$base_path"
    export MAVEN_OPTS="-Xmx512m $2"

    # Not supported by OpenJ9
    java -Xshare:dump &>/dev/null || true

    # Not supported by HotSpot
    java -Xshareclasses:destroyAll &>/dev/null || true

    # delete untracked files
    (cd tmp/commons-collections &>/dev/null && git clean --force)

    # warmup run
    (cd tmp/commons-collections &>/dev/null && \
        mvn --quiet clean install)

    for i in {1..10}
    do
        (cd tmp/commons-collections &>/dev/null && git clean --force)
        (cd tmp/commons-collections &>/dev/null && /usr/bin/time \
            "--format=$jdk_name,$test_name,%e" \
            mvn --quiet clean install \
        ) 2>&1 | tee --append "$results_file"
    done
}

printf '' > "$results_file"

jdk_name='8u202'
benchmark 'baseline' '-Xshare:off'
benchmark 'throughput gc' '-Xshare:off -XX:+UseParallelGC'
benchmark 'CDS' '-Xshare:on'
benchmark 'C1 only' '-Xshare:off -XX:TieredStopAtLevel=1'
benchmark 'no verify' '-Xshare:off -Xverify:none'
benchmark 'tuned' '-Xshare:on -XX:TieredStopAtLevel=1 -XX:+UseParallelGC -Xverify:none'

jdk_name='8u202_openj9'
benchmark 'baseline' ''
benchmark 'throughput gc' '-Xgcpolicy:optthruput'
benchmark 'class cache' '-Xshareclasses:name=mvn -DargLine=-Xshareclasses:none'
benchmark 'quick start' '-Xquickstart'
benchmark 'no verify' '-Xverify:none'
benchmark 'tuned' '-Xquickstart -Xshareclasses:name=mvn -DargLine=-Xquickstart -Xverify:none'

jdk_name='11.0.2'
benchmark 'baseline' '-Xshare:off'
benchmark 'throughput gc' '-Xshare:off -XX:+UseParallelGC'
benchmark 'CDS' '-Xshare:on'
benchmark 'C1 only' '-Xshare:off -XX:TieredStopAtLevel=1'
benchmark 'no verify' '-Xshare:off -Xverify:none'
benchmark 'tuned' '-Xshare:on -XX:TieredStopAtLevel=1 -XX:+UseParallelGC -Xverify:none'

jdk_name='11.0.2_openj9'
benchmark 'baseline' ''
benchmark 'throughput gc' '-Xgcpolicy:optthruput'
benchmark 'class cache' '-Xshareclasses:name=mvn -DargLine=-Xshareclasses:none'
benchmark 'quick start' '-Xquickstart'
benchmark 'no verify' '-Xverify:none'
benchmark 'tuned' '-Xquickstart -Xshareclasses:name=mvn -DargLine=-Xquickstart'
