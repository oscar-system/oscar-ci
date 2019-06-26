IMAGENAME=oscar-ci
METAREPO=git@github.com:oscar-system/oscar-ci
JENKINS_WAR=http://mirrors.jenkins.io/war-stable/latest/jenkins.war
TMUX_CONF=/dev/null

all:
	test -d ci-meta || git clone $(METAREPO) ci-meta
	test -f jenkins.war || wget $(JENKINS_WAR)
	test -f .tmux.conf || cp $(TMUX_CONF) .tmux.conf
	docker build -t $(IMAGENAME) .

rebuild: clean all

clean:
	rm -rf ci-meta .tmux.conf jenkins.war

.PHONY: all clean rebuild
