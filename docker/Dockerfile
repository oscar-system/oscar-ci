# See README.md for instructions for how to set up and run the docker image.

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
  gdb \
  gfortran \
  git \
  host \
  inetutils-ping \
  inetutils-traceroute \
  libboost-dev \
  libcdd-dev \
  libflint-dev \
  libgmp-dev \
  libjson-perl \
  libmpfr-dev \
  libncurses-dev \
  libntl-dev \
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
  locales \
  make \
  mercurial \
  ninja-build \
  openjdk-8-jdk \
  perl \
  python-dev \
  python3-dev \
  ruby-dev \
  screen \
  subversion \
  tmux \
  vim \
  wget \
  zsh
# Configure locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
  locale-gen
ENV LANG=en_US.UTF-8  LANGUAGE=en_US.UTF-8  LC_ALL=en_US.UTF-8   
# Create Jenkins user and directories
ENV JENKINS_HOME=/var/jenkins_home
RUN mkdir -p /usr/share/jenkins /var/jenkins_home && \
  groupadd -r jenkins && \
  useradd --no-log-init -r -g jenkins jenkins \
    -d /home/jenkins -m -s /bin/bash && \
  mkdir -p /home/jenkins/develop
# Utility commands
COPY bin/* /usr/local/bin/
# Controller repo: git clone git@github.com:oscar-system/oscar-ci ci-meta
COPY ci-meta /home/jenkins/develop/ci-meta
# Regular jenkins.war file
COPY jenkins.war /usr/share/jenkins
# Configure environment for user "jenkins"
COPY user/ /tmp/user/
RUN cp -a /tmp/user/. /home/jenkins && \
  rm -rf /tmp/user && \
  chown -R jenkins:jenkins /var/jenkins_home /home/jenkins
# Drop privileges down to user "jenkins"
USER jenkins
EXPOSE 8080
VOLUME /var/jenkins_home
WORKDIR /home/jenkins
# Run shell by default for container testing/development
CMD bash -l
