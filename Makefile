IMG_DEV      = grokloc/grokloc-perl5:dev
IMG_COMPOSE  = grokloc/grokloc-perl5:compose
DOCKER       = docker
DOCKER_RUN   = $(DOCKER) run --rm -it
CWD          = $(shell pwd)
PERL5        = perl
DEV_RUNNER   = morbo
TEST_RUNNER  = yath
UNIT_ENVS    = --env-file ./env/unit.env
PORTS        = -p 3000:3000
BASE         = /grokloc
TIDY         = perltidier
PERLIMPORTS  = perlimports
CRITIC_ARGS  = 
TCRITIC_ARGS = --theme=tests
LIBS         = $(shell find . -type f -name \*pm)
LIB_TESTS    = $(shell find t -type f)
APP_TESTS    = $(shell if [ -d service/app/t ]; then find service/app/t -type f; fi)
APP_MAIN     = service/app/script/app
RUN          = $(DOCKER_RUN) -v $(CWD):$(BASE) -w $(BASE) $(UNIT_ENVS) $(PORTS) $(IMG_DEV)

# Base/CI image.
.PHONY: docker
docker:
	$(DOCKER) build . -f Dockerfile.dev -t $(IMG_DEV)

# Base/CI image. Force.
.PHONY: docker-force
docker-force:
	$(DOCKER) build --no-cache . -f Dockerfile.dev -t $(IMG_DEV)

# Compose build.
.PHONY: compose
compose:
	$(DOCKER) build . -f Dockerfile.compose -t $(IMG_COMPOSE)

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
	$(RUN) make local-check

# Perl tests in container.
.PHONY: test
test:
	$(RUN) make local-test

# perlimports in container.
.PHONY: imports
imports:
	$(RUN) make local-imports

# perltidy in container.
.PHONY: tidy
tidy:
	$(RUN) make local-tidy

# perlcritic in container.
.PHONY: critic
critic:
	$(RUN) make local-critic

# Run all the checkin preconditions. Run tests last to make sure tidy+critic
# hasn't mutated file state incorrectly.
.PHONY: all
all: check tidy critic test

# Perl syntax check.
.PHONY: local-check
local-check:
	for i in `find . -name \*.pm`; do perl -c $$i; done
	for i in `find . -name \*.t`; do perl -c $$i; done

# Perl test.
.PHONY: local-test
local-test:
	$(TEST_RUNNER) $(LIB_TESTS) $(APP_TESTS)

# perlimports.
.PHONY: local-imports
local-imports:
	find lib -type f | grep .pm$ | xargs -n 1 perlimports -i --no-preserved-unused --libs lib,service/app/lib -f
	find lib -type f | grep .t$ | xargs -n 1 perlimports -i --libs lib,service/app/lib -f

# perltidy.
.PHONY: local-tidy
local-tidy:
	find -name \*.pm$ -print0 | xargs -0 perl -pi -e 's/\:(reader|writer|mutator)\;/; #:$$1/msx'
	find -name \*.pm$ -print0 | xargs -0 $(TIDY) -b 2>/dev/null
	find -name \*.pm$ -print0 | xargs -0 perl -pi -e 's/\;\s+\#\:(reader|writer|mutator)/\:$$1\;/msx'
	find -name \*.t$ -print0 | xargs -0 $(TIDY) -b 2>/dev/null
	find -name \*bak$ -delete

# perlcritic.
.PHONY: local-critic
local-critic:
	perlcritic $(CRITIC_ARGS) $(LIBS)
	perlcritic $(TCRITIC_ARGS) $(LIB_TESTS)
