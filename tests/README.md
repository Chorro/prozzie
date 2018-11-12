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
Currently, the few tests implemented are under `tests/`. Use `make check` to
run all of them in your environment. Please note that these tests could be
destructive or add unwanted data to the prozzie installation, so don't execute
it in production code.

Tests function needs to start with `test_`, and they have available the nexts
environments:
:PROZZIE_PREFIX
Where is the prozzie installed. `/opt/prozzie` by default.

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

## Tests
### tests_compose*.bash
Test docker compose forwarding commands.

### tests_config*.bash
Tests the configuration system. They do changes over the prozzie installation,
so you can't run these tests in parallel with others.

### tests_dryconfig.bash
Tests with `config` command that can be parallelized with other tests.

### tests_prozzie*.bash
Test basic CLI behavior, like error returning or help. You can run these tests
in parallel.

### tests_kafka*.bash
Test kafka behavior. They can only create topics, or destroy topics created in
the own test, allowing them to run in parallel.

### tests_install_cancel*.bash
Test that will start the installation process, BUT they are not allowed to
interact with docker daemon. You can execute these tests in parallel with
others.

### tests_setup_cancel*.bash
Test cancellation in the middle of a setup.

### tests_upgrade*.bash
(Will) Test that previous version of prozzie can be upgraded to this version.
This tests can't run in parallel with others.
