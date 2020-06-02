IMAGENAME="$(shell ../bin/show-image-name)"

all: prepare Dockerfile
	docker build -t $(IMAGENAME) .

prepare: credentials.yaml
	test -d user || mkdir -p user

Dockerfile: Dockerfile.in
	erb $< >$@

credentials.yaml:
	@echo "| Please supply a file credentials.yaml"
	@echo "| An empty file can be created with 'touch credentials.yaml'"
	@echo "| if needed."
	@echo "|"
	@echo "| Format is:"
	@echo "|"
	@echo "| jobname:"
	@echo "|   repo: orgname/reponame"
	@echo "|   key: private SSH key"
	@echo "|"
	@echo "| Repeat for each job as needed."
	@echo "|"
	@echo "| See example-credentials.yaml for an example."
	@exit 1


clean:
	rm -rf ci-meta user jenkins.war credentials.yaml Dockerfile

.PHONY: all clean rebuild prepare
