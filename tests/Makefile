
all: coverage

DOCKER ?= docker
COVERAGE_OUT?=coverage.html
KCOV=kcov

tests_sh := $(wildcard tests_*.bash)
tests_out := $(tests_sh:.bash=.out)
coverages := $(tests_sh:.bash=.cov)

docker-images: $(patsubst %/,%,$(dir $(wildcard */Dockerfile)))

.PHONY : all clean docker-images check coverage

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

%: %/Dockerfile
	$(DOCKER) build -t gcr.io/wizzie-registry/prozzie-test-env:$(@) -f $(@)/Dockerfile .
