# This is intended to be run with:
#
#   docker run -it -v jenkins_home:/var/jenkins_home -p 8080:8080 <image-name>
#
# where `jenkins_home` is a docker volume, which can be created with:
#
#   docker create volume jenkins_home
#
# This volume will store Jenkins state (logs, workspaces) between runs and
# reboots.
#
# You can alternatively use a bind mount instead of a docker volume to
# store Jenkins state in the file system. In this case, please follow
# the Jenkins documentation for ensuring that the user and group ids on
# host system and container are properly matched up, or you may run into
# permission problems.
#
# To build a docker image, run `make` or manually perform the following
# steps:
#
#   1. Create an empty directory and cd to it.
#   2. Copy `Dockerfile` to this directory.
#   3. git clone git@github.com:oscar-system/oscar-ci ci-meta
#   4. wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war
#   5. cp /dev/null .tmux.conf
#   6. docker build -t <image-name> .
#
# The image is currently designed to drop you into a shell to debug the
# Jenkins setup. In order to start Jenkins by default, replace the current
# CMD directive at the end of the Dockerfile with:
#
#   CMD java -jar /usr/share/jenkins/jenkins.war
#
# You can also configure tmux by putting in a .tmux.conf file of your
# choice. This allows you to run Jenkins in one tmux tab and perform
# other tasks in other ones. The above instructions will leave .tmux.conf
# empty. If you need other files in the jenkins setup (such as a .bashrc),
# add them to the COPY directive.
#
# To start Jenkins from the container shell, run:
#
#   CMD java -jar /usr/share/jenkins/jenkins.war
#
# The ci-meta directory is currently pulled from local storage, rather
# than from GitHub directly. Again, this is to allow you to introduce
# local commits for debugging purposes. In the long-term, we will pull
# directly from GitHub.

FROM ubuntu:18.04
# Basic development and admin tools
RUN apt-get update && apt-get install -y \
  autoconf \
  automake \
  cmake \
  curl \
  dnsutils \
  g++ \
  gcc \
  gfortran \
  git \
  host \
  inetutils-ping \
  inetutils-traceroute \
  libboost-dev \
  libgmp-dev \
  libjson-perl \
  libmpfr-dev \
  libncurses-dev \
  libpcre2-dev \
  libperl-dev \
  libreadline-dev \
  libterm-readkey-perl \
  libterm-readline-gnu-perl \
  libtool-bin \
  libxml-libxml-perl \
  libxml-libxslt-perl \
  libxml-writer-perl \
  libxml2-dev \
  libxslt1-dev \
  make \
  mercurial \
  ninja-build \
  openjdk-8-jdk \
  perl \
  python-dev \
  python3-dev \
  ruby-dev \
  subversion \
  tmux \
  vim \
  wget \
  zsh
# Create Jenkins user and directories
ENV JENKINS_HOME /var/jenkins_home
RUN mkdir -p /usr/share/jenkins /var/jenkins_home && \
  groupadd -r jenkins && \
  useradd --no-log-init -r -g jenkins jenkins \
    -d /home/jenkins -m -s /bin/bash && \
  mkdir -p /home/jenkins/develop
# Controller repo: git clone git@github.com:oscar-system/oscar-ci ci-meta
COPY ci-meta /home/jenkins/develop/ci-meta
# Regular jenkins.war file
COPY jenkins.war /usr/share/jenkins
# For docker development to have multiple screen; just
# touch .tmux.conf if not needed for now.
COPY .tmux.conf /home/jenkins
# Drop down to user jenkins, fix access permissions
RUN chown -R jenkins:jenkins /var/jenkins_home /home/jenkins
USER jenkins
EXPOSE 8080
WORKDIR /home/jenkins
# Run shell by default for container testing/development
CMD bash -l
