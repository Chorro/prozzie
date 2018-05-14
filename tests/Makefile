
all: coverage

DOCKER ?= docker
COVERAGE_OUT?=coverage
KCOV=kcov

docker-images: $(patsubst %/,%,$(dir $(wildcard */Dockerfile)))
.PHONY: docker-images $(docker-images)

tests_sh = ./tests.sh

check:
	$(tests_sh)

coverage:
	$(KCOV) $(KCOV_FLAGS) $(KCOV_OUT) $(tests_sh)

%: %/Dockerfile
	$(DOCKER) build -t gcr.io/wizzie-registry/prozzie-test-env:$(@) -f $(@)/Dockerfile .
