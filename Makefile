IMG_CI       = grokloc/grokloc-perl5:ci
IMG_DEV      = grokloc/grokloc-perl5:dev
DOCKER       = docker
DOCKER_RUN   = $(DOCKER) run --rm -it
PERL5        = perl
DEV_RUNNER   = morbo
TEST_RUNNER  = yath
UNIT_ENVS    = --env-file ./env/unit.env
PORTS        = -p 3000:3000
CWD          = $(shell pwd)
BASE         = /grokloc
TIDY         = perltidy
CRITIC_ARGS  =
TCRITIC_ARGS = --theme=tests
LIBS         = $(shell find lib -type f -name \*pm)
LIB_TESTS    = $(shell find t -type f)
APP_TESTS    = $(shell if [ -d service/app/t ]; then find service/app/t -type f; fi)
APP_MAIN     = service/app/script/app
RUN          = $(DOCKER_RUN) -v $(CWD):$(BASE) -w $(BASE) $(UNIT_ENVS) $(PORTS) $(IMG_DEV)

# Base/CI image.
.PHONY: docker-ci
docker-ci:
	$(DOCKER) build . -f Dockerfile.ci -t $(IMG_CI)

# Dev image.
.PHONY: docker-dev
docker-dev: docker-ci
	$(DOCKER) build . -f Dockerfile.dev -t $(IMG_DEV)

# Shell in container.
.PHONY: shell
shell:
	$(RUN) /bin/bash

# Perl re.pl in container.
.PHONY: re.pl
re.pl:
	$(RUN) re.pl

# Perl syntax check in container.
.PHONY: check
check:
	$(RUN) make ci-check

# Perl tests in container.
.PHONY: test
test:
	$(RUN) make ci-test

# Perlcritic in container.
.PHONY: critic
critic:
	$(RUN) make ci-critic

# Perltidy in container.
.PHONY: tidy
tidy:
	$(RUN) make ci-tidy

# Perl syntax check.
.PHONY: ci-check
ci-check:
	for i in `find . -name \*.pm`; do perl -c $$i; done
	for i in `find . -name \*.t`; do perl -c $$i; done

# Perl test.
.PHONY: ci-test
ci-test:
	$(TEST_RUNNER) $(LIB_TESTS) $(APP_TESTS)

# Perlcritic.
.PHONY: ci-critic
ci-critic:
	perlcritic $(CRITIC_ARGS) $(LIBS)
	perlcritic $(TCRITIC_ARGS) $(LIB_TESTS)

# Perltidy.
.PHONY: ci-tidy
ci-tidy:
	find -name \*.pm -print0 | xargs -0 $(TIDY) -b
	find -name \*.t -print0 | xargs -0 $(TIDY) -b
	find -name \*bak -delete
