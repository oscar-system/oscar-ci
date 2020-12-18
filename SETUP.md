# Oscar CI

This document describes the steps used to install the Oscar CI
system. The system is intended to be installed on a dedicated
account. The system should have sufficiently recent versions of
Java, Ruby, and Python3 available.

# Install CI configuration

The software that we use to control Jenkins can be found in its own
GitHub repository.

Either get a new version:

    git clone https://github.com/oscar-system/oscar-ci

or update the current one:

    git -C oscar-ci pull

Updates are rarely necessary, as the information that Jenkins does not
already automatically fetch from elsewhere are uncommon. The most common
case would be an update of the docker file.

# Build docker & update Jenkins

First, ensure that you have a working credentials file in
`oscar-ci/docker/credentials.yaml`. This is needed to store the
credentials to upload build results to GitHub. Otherwise, the `make`
step will fail. An empty file can be used if no GitHub upload is
desired.

    make -C oscar-ci/docker
    oscar-ci/bin/get-jenkins

# Start Jenkins

You can use either of the following to start Jenkins.

    oscar-ci/bin/jenkins
    oscar-ci/bin/jenkins-nosetup

The second version bypasses the setup wizard in case you have already
programmatically generated the configuration and is not normally
recommended. For an example where this is used, see
<https://github.com/oscar-system/oscar-ci-vm>.

If the system has already been set up, either form can be used.

Jenkins data is normally stored in `~/jenkins/oscar-ci`.

# Environment variables

The following environment variables can be set:

* `OSCAR_CI_NAME` is the name of the Jenkins configuration.
  Jenkins data goes to `~/jenkins/$OSCAR_CI_NAME`. This
  can be used to run a separate test installation that does
  not affect normal operations.
* `JENKINS_VER` is the Jenkins version and defaults to `latest`.
  This is useful if you want to pin Jenkins to a specific
  version. However, frequent security updates mean that this
  is of limited usefulness.
