MACOS_SWIPL := /Applications/SWI-Prolog.app/Contents/MacOS/swipl
SWIPL ?= $(if $(wildcard $(MACOS_SWIPL)),$(MACOS_SWIPL),$(shell command -v swipl 2>/dev/null))

.PHONY: run test coverage lint check check-swipl

check-swipl:
	@test -n "$(SWIPL)"
	@test -x "$(SWIPL)"

run: check-swipl
	"$(SWIPL)" -s oca.pl

test: check-swipl
	"$(SWIPL)" -q -f tests/run_tests.pl

coverage: check-swipl
	"$(SWIPL)" -q -f tests/run_tests.pl -- --coverage

lint: check-swipl
	"$(SWIPL)" -q -s oca.pl -g "use_module(library(check)), check, halt"

check: lint coverage
