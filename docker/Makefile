IMAGENAME=oscar-ci
METAREPO=git@github.com:oscar-system/oscar-ci
JENKINS_VER=latest
JENKINS_WAR=http://mirrors.jenkins.io/war-stable/$(JENKINS_VER)/jenkins.war

all: prepare
	docker build -t $(IMAGENAME) .
prepare:
	test -d ci-meta || git clone $(METAREPO) ci-meta
	unzip -tqq jenkins.war >/dev/null 2>&1 || wget $(JENKINS_WAR)
	test -d user || mkdir -p user

clean:
	rm -rf ci-meta user jenkins.war

.PHONY: all clean rebuild prepare
