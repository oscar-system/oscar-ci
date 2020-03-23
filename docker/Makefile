IMAGENAME=oscar-ci
METAREPO=git@github.com:oscar-system/oscar-ci
JENKINS_VER=latest
JENKINS_WAR=http://mirrors.jenkins.io/war-stable/$(JENKINS_VER)/jenkins.war

all: prepare
	docker build -t $(IMAGENAME) .

prepare: credentials.yaml
	test -d ci-meta || git clone $(METAREPO) ci-meta
	unzip -tqq jenkins.war >/dev/null 2>&1 || wget $(JENKINS_WAR)
	test -d user || mkdir -p user

credentials.yaml:
	@echo "| Please supply a file credentials.yaml"
	@echo "| An empty file can be created with 'touch credentials.yaml'"
	@echo "| if needed."
	@echo "|"
	@echo "| Format is:"
	@echo "|"
	@echo "| jobname:"
	@echo "|   user: username"
	@echo "|   repo: orgname/reponame"
	@echo "|   token: GitHub API Token"
	@echo "|"
	@echo "| Repeat for each workspace as needed."
	@exit 1


clean:
	rm -rf ci-meta user jenkins.war credentials.yaml

.PHONY: all clean rebuild prepare
