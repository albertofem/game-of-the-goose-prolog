MACOS_SWIPL := /Applications/SWI-Prolog.app/Contents/MacOS/swipl
SWIPL ?= $(if $(wildcard $(MACOS_SWIPL)),$(MACOS_SWIPL),$(shell command -v swipl 2>/dev/null))

.PHONY: test coverage check-swipl

check-swipl:
	@test -n "$(SWIPL)"
	@test -x "$(SWIPL)"

test: check-swipl
	"$(SWIPL)" -q -f tests/run_tests.pl

coverage: check-swipl
	"$(SWIPL)" -q -f tests/run_tests.pl -- --coverage
