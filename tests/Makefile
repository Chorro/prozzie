
all: coverage

DOCKER ?= docker
COVERAGE_OUT?=coverage.html
KCOV=kcov

tests_sh := $(wildcard tests_*.bash)
tests_out := $(tests_sh:.bash=.out)
coverages := $(tests_sh:.bash=.cov)

dockerfiles := $(wildcard */Dockerfile)
docker_images := $(patsubst %/,%,$(dir $(dockerfiles)))

.PHONY : all clean docker-images $(docker_images) check coverage

docker-images: $(docker_images)

check: $(tests_out)

tests_%.out: SHELL=/usr/bin/env bash -o pipefail
tests_%.out: tests_%.bash
	@"./$<" | tee "$@"

tests_%.cov: tests_%.bash
	$(KCOV) $(KCOV_FLAGS) "$@" "$<"

coverage: $(COVERAGE_OUT)
$(COVERAGE_OUT): $(coverages)
	$(KCOV)  --merge "$@" $^

clean:
	rm -rfv $(tests_out) $(coverages) $(COVERAGE_OUT)

$(docker_images): %: %/Dockerfile
	$(strip $(DOCKER) build --build-arg \
		BASE_DOCKER_IMAGE=$(subst -,:,$@) \
		-t gcr.io/wizzie-registry/prozzie-test-env:$(@) \
		-f $(@)/Dockerfile .)
