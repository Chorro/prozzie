# Prozzie tests system
Tests system is divided into two parts to be able to test prozzie in a
multi-platform environment.

## Docker images
Docker images are the different environments in what prozzie is supposed to be
successfully installed & executed. Every docker image has an
${image}/Dockerfile file associated (for example, ubuntu-16.04/Dockerfile),
and you can generate it with `make ${image}`. To build all images, you can
use the make `docker-images` target.

Every one of these images is supposed to run in circleci and to pass all the
tests specified in the `tests.sh` file, explained in the next section.

## Actual tests
### Raw tests
Currently, the few tests implemented are in tests.sh. Use `make check` to run
all of them in your environment. Please note that these tests could be
destructive or add unwanted data to the prozzie installation, so don't execute
it in production code.

### Coverage
You can use `make coverage` to get the coverage, what run the test suite under
[kcov](https://github.com/SimonKagstrom/kcov). Please make sure that new
features are well covered in your tests.

The coverage target honor the next variables:
:KCOV_FLAGS
Currently providing the prozzie cli and installer path, to get useful coverage
reports
:KCOV_OUT
Location of coverage report. `coverage.out` by default.
