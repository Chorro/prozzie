
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

BUILD_ARGS:=CXX EXPECT IS_CENTOS KAFKACAT LIBDW LIBDW_DEV LIBELF_DEV LIBZ_DEV \
	PKG_CONFIG PKG_MANAGER_UPDATE PKG_MANAGER_INSTALL PSLIST TCL TCLLIB

# Debian build arguments
CXX_debian = g++
EXPECT_debian = expect
IS_CENTOS_debian = false
LIBDW_debian = libdw1
LIBDW_DEV_debian = libdw-dev
LIBZ_DEV_debian = libz-dev
PSLIST_debian = pslist
KAFKACAT_debian = kafkacat
PKG_CONFIG_debian = pkg-config
PKG_MANAGER_UPDATE_debian = apt update
PKG_MANAGER_INSTALL_debian = env DEBIAN_FRONTEND=noninteractive \
	apt install --no-install-recommends -y
TCL_debian = tcl8.6
TCLLIB_debian = tcllib

# Ubuntu uses the same arguments as debian
$(foreach arg, $(BUILD_ARGS), $(eval $(arg)_ubuntu = $($(arg)_debian)))

# Centos build arguments
CXX_centos := gcc-c++
IS_CENTOS_centos = true
LIBDW_DEV_centos = libdwarf-devel
LIBDW_centos = libdwarf
LIBELF_DEV_centos = elfutils-devel
LIBZ_DEV_centos = zlib-devel
PKG_MANAGER_UPDATE_centos = true # Not needed
PKG_MANAGER_INSTALL_centos = yum install -y

# Expand to Dockerfile argument $(1) assignment of distro $(2)
arg_distro = $(1)='$($(1)_$(firstword $(subst -, ,$2)))'

# Get the base docker image of the target
target_base_docker = $(subst -,:,$@)

# Get the distro family of the target
distro_family_target = $(firstword $(subst -, ,$@))

$(docker_images): %: %/Dockerfile
	$(strip $(DOCKER) build \
		--build-arg BASE_DOCKER_IMAGE=$(target_base_docker) \
		$(foreach arg,$(BUILD_ARGS),--build-arg \
			$(call arg_distro,$(arg),$(distro_family_target))) \
		-t gcr.io/wizzie-registry/prozzie-test-env:$(@) \
		-f $(@)/Dockerfile .)
