# Overview

This is the control repository for the OSCAR continuous integration
server, which contains the Jenkins setup, integration tests, and
the necessary parts for building a docker image for a server.

# Docker image

For building a docker image for a server (e.g. for local testing),
please check [docker/README.md](docker/README.md).

# Writing tests

In order to add an integration test, add an executable script file
(e.g. a shell script or a Perl/Python/Ruby program) to the tests
directory and add an entry for it to `tests/config.py`. By default,
the test will have Julia available on its path and the Jenkins
workspace will be the current directory. Recent versions of Perl,
Python 2, Python 3, and Ruby are also available.

# Jenkins

The `Jenkinsfile` contains the main logic for telling Jenkins how to
build software and run tests.
