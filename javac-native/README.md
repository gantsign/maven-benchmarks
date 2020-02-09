# Maven Native Javac Benchmarks

**Note:** the scripts have been updated to support GraalVM 19.3.1 but the data
hasn't been updated with new benchmark results. The the data remains the same as
the [Native javac built with GraalVM](https://medium.com/@john_freeman/native-javac-with-graalvm-ddcc18a53edb)
Medium article.

To view the benchmark script as used in the Medium article view the [medium-29Apr2019](https://github.com/gantsign/maven-benchmarks/tree/medium-29Apr2019/javac-native) tag.

## Prerequisites

* Ubuntu Linux

* Python

    Install with: `sudo apt install python`

* Python PIP

    Install with: `sudo apt install python-pip`

* [pyenv](https://github.com/pyenv/pyenv)

    Install with: `curl https://pyenv.run | bash`

* [pipenv](https://github.com/pypa/pipenv)

    Install with: `pip install --user pipenv`

**Once you've installed the dependencies you need to restart your terminal window.**

## Install project Python dependencies

Run the following from the project root:

```bash
cd javac-native
pipenv install
```

## Install other project dependencies

You only need to run this once. Run the following from the project root:

```bash
cd javac-native
./prepare.sh
```

## Run benchmark

This will run the benchmark and write the results to `results.csv`. Run the
following from the project root:

```
cd javac-native
./run-benchmark.sh
```

**Warning:** running the benchmark takes a few hours. You can skip this step to
view my results.

## View results

Run the following from the project root:

```bash
cd javac-native
pipenv run jupiter notebook
```

Look for a URL like `http://localhost:8888/?token=<token>` in the console output
and open thee URL in your web browser.

Navigate to `JavacNative.ipynb`, `MavenJavacNative.ipynb`,
`MavenNoTestsJavacNative.ipynb` to to view the results.

## Test environment

The Machine I used for testing was a
[Lenovo YOGA 900 13ISK](https://www.notebookcheck.net/Lenovo-Yoga-900-13ISK-Convertible-Review.154217.0.html)
running Ubuntu Bionic under Oracle VirtualBox 5.2.16 using a Intel Core i7-6500U
CPU and 512 GB SSD.

## License

This software is licensed under the terms in the file named "[LICENSE](LICENSE)"
in the root directory of this project.

## Author Information

John Freeman

GantSign Ltd.
Company No. 06109112 (registered in England)
