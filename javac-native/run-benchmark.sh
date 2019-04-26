#!/usr/bin/env bash

set -e

base_path="$(pwd)/tmp/maven/3.6.1/bin:$PATH"

src_dir="$PWD/tmp/commons-collections/src/main/java"
classes_dir="$PWD/tmp/commons-collections/target/classes"
options_file="$PWD/tmp/javac_options"
settings_file="$PWD/settings.xml"
export GRAAL_HOME="$PWD/tmp/jdk/8u202_graalvm-ce"

(cd "$src_dir" &>/dev/null && echo -source 1.8 -target 1.8 -sourcepath . \
    -g -nowarn -encoding iso-8859-1 -d "$classes_dir" \
    $(find . -name '*.java') > "$options_file")

javac_benchmark() {
    test_name="$1"
    native="$2"
    javac_options="$3"

    export JAVA_HOME="$(pwd)/tmp/jdk/$jdk_name"
    export PATH="$JAVA_HOME/bin:$base_path"

    # Not supported by OpenJ9
    java -Xshare:dump &>/dev/null || true

    # Not supported by HotSpot
    java -Xshareclasses:destroyAll &>/dev/null || true

    if [[ $native == true ]]; then
        javac_exe="$PWD/tmp/bin/javac-native"
    else
        javac_exe="$JAVA_HOME/bin/javac"
    fi

    # warmup run
    rm -rf "$classes_dir"
    mkdir -p "$classes_dir"
    (cd "$src_dir" &>/dev/null && \
        "$javac_exe" "@$options_file" $javac_options 2>&1 | \
        (grep -E -v "^Note:" || true))

    for i in {1..10}
    do
        rm -rf "$classes_dir"
        mkdir -p "$classes_dir"
        (cd "$src_dir" &>/dev/null && /usr/bin/time \
            "--format=$jdk_name,$test_name,%e" \
            "$javac_exe" "@$options_file" $javac_options \
        ) 2>&1 | (grep -E -v "^Note:" || true) | tee --append "$results_file"
    done
}

mvn_benchmark() {
    test_name="$1"
    native="$2"

    export JAVA_HOME="$(pwd)/tmp/jdk/$jdk_name"
    export PATH="$JAVA_HOME/bin:$base_path"
    export MAVEN_OPTS="-Xmx512m $3"

    if [[ $native == true ]]; then
        maven_args="-s $settings_file"
    else
        maven_args=''
    fi

    # Not supported by OpenJ9
    java -Xshare:dump &>/dev/null || true

    # Not supported by HotSpot
    java -Xshareclasses:destroyAll &>/dev/null || true

    # delete untracked files
    (cd tmp/commons-collections &>/dev/null && git clean --force)

    # warmup run
    (cd tmp/commons-collections &>/dev/null && \
        mvn --quiet clean install $maven_args)

    for i in {1..10}
    do
        (cd tmp/commons-collections &>/dev/null && git clean --force)
        (cd tmp/commons-collections &>/dev/null && /usr/bin/time \
            "--format=$jdk_name,$test_name,%e" \
            mvn --quiet clean install $maven_args \
        ) 2>&1 | tee --append "$results_file"
    done
}

mvn_no_tests_benchmark() {
    test_name="$1"
    native="$2"

    export JAVA_HOME="$(pwd)/tmp/jdk/$jdk_name"
    export PATH="$JAVA_HOME/bin:$base_path"
    export MAVEN_OPTS="-Xmx512m $3"

    if [[ $native == true ]]; then
        maven_args="-s $settings_file"
    else
        maven_args=''
    fi

    # Not supported by OpenJ9
    java -Xshare:dump &>/dev/null || true

    # Not supported by HotSpot
    java -Xshareclasses:destroyAll &>/dev/null || true

    # delete untracked files
    (cd tmp/commons-collections &>/dev/null && git clean --force)

    # warmup run
    (cd tmp/commons-collections &>/dev/null && \
        mvn --quiet clean install -DskipTests $maven_args)

    for i in {1..10}
    do
        (cd tmp/commons-collections &>/dev/null && git clean --force)
        (cd tmp/commons-collections &>/dev/null && /usr/bin/time \
            "--format=$jdk_name,$test_name,%e" \
            mvn --quiet clean install -DskipTests $maven_args \
        ) 2>&1 | tee --append "$results_file"
    done
}


echo '*** javac benchmarks ***'

results_file="$(pwd)/javac_results.csv"
printf '' > "$results_file"

jdk_name='8u212'
javac_benchmark 'baseline' false '-J-Xshare:off'
javac_benchmark 'tuned' false '-J-Xshare:on -J-XX:TieredStopAtLevel=1 -J-XX:+UseParallelGC -J-Xverify:none'

jdk_name='8u212_openj9'
javac_benchmark 'baseline' false ''
javac_benchmark 'tuned' false '-J-Xquickstart -J-Xshareclasses:name=javac -J-Xverify:none'

jdk_name='8u202_graalvm-ce'
javac_benchmark 'baseline' false '-J-Xshare:off'
javac_benchmark 'tuned' false '-J-Xshare:off -J-Dgraal.CompilerConfiguration=economy'
javac_benchmark 'native' true ''

jdk_name='11.0.3'
javac_benchmark 'baseline' false '-J-Xshare:off'
javac_benchmark 'tuned' false '-J-Xshare:on -J-XX:TieredStopAtLevel=1 -J-XX:+UseParallelGC -J-Xverify:none'

jdk_name='11.0.3_openj9'
javac_benchmark 'baseline' false ''
javac_benchmark 'tuned' false '-J-Xquickstart -J-Xshareclasses:name=javac -J-Xverify:none'

echo '*** maven benchmarks ***'

results_file="$(pwd)/mvn_results.csv"
printf '' > "$results_file"

jdk_name='8u212'
mvn_benchmark 'baseline' false '-Xshare:off'
mvn_benchmark 'baseline+native' true '-Xshare:off'
mvn_benchmark 'tuned' false '-Xshare:on -XX:TieredStopAtLevel=1 -XX:+UseParallelGC -Xverify:none'
mvn_benchmark 'tuned+native' true '-Xshare:on -XX:TieredStopAtLevel=1 -XX:+UseParallelGC -Xverify:none'

jdk_name='8u212_openj9'
mvn_benchmark 'baseline' false ''
mvn_benchmark 'baseline+native' true ''
mvn_benchmark 'tuned' false '-Xquickstart -Xshareclasses:name=mvn -DargLine=-Xquickstart -Xverify:none'
mvn_benchmark 'tuned+native' true '-Xquickstart -Xshareclasses:name=mvn -DargLine=-Xquickstart -Xverify:none'

jdk_name='8u202_graalvm-ce'
mvn_benchmark 'baseline' false '-Xshare:off'
mvn_benchmark 'baseline+native' true '-Xshare:off'
mvn_benchmark 'tuned' false '-Xshare:off -Dgraal.CompilerConfiguration=economy'
mvn_benchmark 'tuned+native' true '-Xshare:off -Dgraal.CompilerConfiguration=economy'

jdk_name='11.0.3'
mvn_benchmark 'baseline' false '-Xshare:off'
mvn_benchmark 'baseline+native' true '-Xshare:off'
mvn_benchmark 'tuned' false '-Xshare:on -XX:TieredStopAtLevel=1 -XX:+UseParallelGC -Xverify:none'
mvn_benchmark 'tuned+native' true '-Xshare:on -XX:TieredStopAtLevel=1 -XX:+UseParallelGC -Xverify:none'

jdk_name='11.0.3_openj9'
mvn_benchmark 'baseline' false ''
mvn_benchmark 'baseline+native' true ''
mvn_benchmark 'tuned' false '-Xquickstart -Xshareclasses:name=mvn -DargLine=-Xquickstart -Xverify:none'
mvn_benchmark 'tuned+native' true '-Xquickstart -Xshareclasses:name=mvn -DargLine=-Xquickstart -Xverify:none'

echo '*** maven no tests benchmarks ***'

results_file="$(pwd)/mvn_no_tests_results.csv"
printf '' > "$results_file"

jdk_name='8u212'
mvn_no_tests_benchmark 'baseline' false '-Xshare:off'
mvn_no_tests_benchmark 'baseline+native' true '-Xshare:off'
mvn_no_tests_benchmark 'tuned' false '-Xshare:on -XX:TieredStopAtLevel=1 -XX:+UseParallelGC -Xverify:none'
mvn_no_tests_benchmark 'tuned+native' true '-Xshare:on -XX:TieredStopAtLevel=1 -XX:+UseParallelGC -Xverify:none'

jdk_name='8u212_openj9'
mvn_no_tests_benchmark 'baseline' false ''
mvn_no_tests_benchmark 'baseline+native' true ''
mvn_no_tests_benchmark 'tuned' false '-Xquickstart -Xshareclasses:name=mvn -DargLine=-Xquickstart -Xverify:none'
mvn_no_tests_benchmark 'tuned+native' true '-Xquickstart -Xshareclasses:name=mvn -DargLine=-Xquickstart -Xverify:none'

jdk_name='8u202_graalvm-ce'
mvn_no_tests_benchmark 'baseline' false '-Xshare:off'
mvn_no_tests_benchmark 'baseline+native' true '-Xshare:off'
mvn_no_tests_benchmark 'tuned' false '-Xshare:off -Dgraal.CompilerConfiguration=economy'
mvn_no_tests_benchmark 'tuned+native' true '-Xshare:off -Dgraal.CompilerConfiguration=economy'

jdk_name='11.0.3'
mvn_no_tests_benchmark 'baseline' false '-Xshare:off'
mvn_no_tests_benchmark 'baseline+native' true '-Xshare:off'
mvn_no_tests_benchmark 'tuned' false '-Xshare:on -XX:TieredStopAtLevel=1 -XX:+UseParallelGC -Xverify:none'
mvn_no_tests_benchmark 'tuned+native' true '-Xshare:on -XX:TieredStopAtLevel=1 -XX:+UseParallelGC -Xverify:none'

jdk_name='11.0.3_openj9'
mvn_no_tests_benchmark 'baseline' false ''
mvn_no_tests_benchmark 'baseline+native' true ''
mvn_no_tests_benchmark 'tuned' false '-Xquickstart -Xshareclasses:name=mvn -DargLine=-Xquickstart -Xverify:none'
mvn_no_tests_benchmark 'tuned+native' true '-Xquickstart -Xshareclasses:name=mvn -DargLine=-Xquickstart -Xverify:none'
