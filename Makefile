# Tender — the targets CI runs, so local and CI cannot disagree.
#
# iOS only, in Swift. No Docker target: Xcode does not run in a container, so
# the reproducible-build story is a pinned Xcode in the README and CI on macOS.

DOMAIN  := TenderDomain
PROJECT := Tender.xcodeproj
SCHEME  := Tender
DERIVED := .build/DerivedData
DATASET ?= $(abspath ../tender-dataset)

# The simulator to test on. `xcrun simctl list devices available` to pick.
SIM ?= $(shell xcrun simctl list devices available 2>/dev/null | grep -m1 iPhone | grep -oE '[0-9A-F-]{36}')
DEST := platform=iOS Simulator,id=$(SIM)

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

# --- the gate ---------------------------------------------------------------

.PHONY: ci
ci: doc-check design-check counts-check copy-check network-check splash-check speech-check dataset-check model-check analyze test coverage-gate ## Everything CI runs

.PHONY: gates
gates: doc-check design-check counts-check copy-check network-check splash-check speech-check coverage-gate ## The blocking gates alone. These never go yellow.

# --- the dataset: Phase 1 ---------------------------------------------------
#
# Yellow with no dataset, so a fresh clone is green and honest; red when one is
# present and short. `docs/DATASET-GUIDE.md` is what the photographer is handed.

.PHONY: dataset-check
dataset-check: ## Count the dataset against Phase 1's gate:  make dataset-check [DATASET=path]
	@DATASET="$(DATASET)" python3 scripts/dataset-check.py

.PHONY: dataset-import
dataset-import: ## File a batch:  make dataset-import CLASS=n500new FACE=back COND=worn LIGHT=dusk D=<dir>
	@if [ -z "$(CLASS)" ] || [ -z "$(FACE)" ] || [ -z "$(COND)" ] || [ -z "$(LIGHT)" ] || [ -z "$(D)" ]; then \
	  echo "\033[0;33m!\033[0m usage:  make dataset-import CLASS=n500new FACE=back COND=worn LIGHT=dusk D=<dir>"; exit 64; fi
	@DATASET="$(DATASET)" python3 scripts/dataset-import.py "$(CLASS)" "$(FACE)" "$(COND)" "$(LIGHT)" "$(D)"

.PHONY: dataset-manifest
dataset-manifest: ## Write MANIFEST.md beside the dataset, counted from the files
	@DATASET="$(DATASET)" python3 scripts/dataset-manifest.py

.PHONY: doc-check
doc-check: ## Verify the documentation is present, well-formed and current
	@scripts/doc-check.sh

.PHONY: design-check
design-check: ## Fail if DESIGN.md disagrees with the tokens it documents
	@python3 scripts/design-check.py

.PHONY: counts-check
counts-check: ## Fail if a document quotes a figure the code does not produce
	@python3 scripts/counts-check.py

.PHONY: copy-check
copy-check: ## Fail if anything the app can say implies a note is genuine (ADR-0003)
	@python3 scripts/copy-check.py

.PHONY: network-check
network-check: ## Fail if the app has a network path
	@scripts/network-check.sh

.PHONY: splash-check
splash-check: ## Fail if the launch screen, icon or mark are not what the palette says
	@python3 scripts/splash-check.py

.PHONY: speech-check
speech-check: ## Fail if docs/SPEECH.md is not what the source produces
	@python3 scripts/speech-list.py --check

.PHONY: speech-list
speech-list: ## Write docs/SPEECH.md — everything the app says, derived from the source
	@python3 scripts/speech-list.py

.PHONY: brandmark
# Not run by `ci`, which checks rather than writes. `splash-check` fails if
# you forget to run this after a palette change.
brandmark: ## Redraw the icon and docs/mark.png from the palette
	@python3 scripts/brandmark.py

# --- the model: Phase 2 -----------------------------------------------------

.PHONY: model
# Trains with Create ML on DATASET/train, evaluates on DATASET/test, writes the
# model and docs/MODEL-REPORT.md. The report is the published claim; the model
# is an artefact and is not tracked.
model: ## Train the classifier and write docs/MODEL-REPORT.md:  make model [ITERATIONS=25]
	@TENDER_ROOT="$(CURDIR)" DATASET="$(DATASET)" ITERATIONS="$(or $(ITERATIONS),25)" swift scripts/train.swift 2>&1 | grep -vE 'DeprecatedDeclaration|^\s*[0-9]+ \||^\s*\||`-'

.PHONY: model-check
model-check: ## Refuse the model if the report says any class is below 95% or ₦500 and ₦1000 are ever confused
	@python3 scripts/model-check.py

# --- code -------------------------------------------------------------------

.PHONY: setup
setup: ## Nothing to install: Xcode 26 and a simulator runtime
	@xcodebuild -version | head -1
	@xcrun simctl list runtimes | grep -m1 iOS || echo "\033[0;33m!\033[0m no iOS simulator runtime — install one from Xcode > Settings > Components"
	@python3 -c 'import PIL' 2>/dev/null || echo "\033[0;33m!\033[0m Pillow is needed by make brandmark:  python3 -m pip install --user Pillow"

.PHONY: analyze
# Warnings are errors in the project already (SWIFT_TREAT_WARNINGS_AS_ERRORS);
# this makes the package the same, then runs the purity lint so it cannot be
# skipped by running the analyzer alone.
analyze: ## Build the domain with warnings as errors, plus the domain-purity check
	cd $(DOMAIN) && swift build -Xswiftc -warnings-as-errors
	@$(MAKE) --no-print-directory domain-purity

.PHONY: domain-purity
domain-purity: ## Fail if the domain imports anything, or touches the clock or randomness
	@python3 scripts/domain-purity.py

.PHONY: test
# The domain first: seconds, no simulator. Then the app on the simulator,
# which is where the accessibility audit runs.
test: test-domain test-app ## Run the test suite

.PHONY: test-domain
test-domain: ## The domain package's tests, on macOS, in seconds
	cd $(DOMAIN) && swift test

.PHONY: test-app
test-app: ## The app's unit and UI tests on the simulator
	@[ -n "$(SIM)" ] || { echo "\033[0;33m!\033[0m no simulator found:  make test-app SIM=<udid>"; exit 64; }
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination "$(DEST)" \
	  -derivedDataPath $(DERIVED) CODE_SIGNING_ALLOWED=NO -quiet
	@python3 scripts/test-summary.py $(DERIVED)

.PHONY: build
build: ## Build the app for the simulator
	xcodebuild build -project $(PROJECT) -scheme $(SCHEME) -destination "$(DEST)" \
	  -derivedDataPath $(DERIVED) CODE_SIGNING_ALLOWED=NO -quiet

.PHONY: coverage
coverage: ## Domain coverage with the per-file breakdown
	cd $(DOMAIN) && swift test --enable-code-coverage >/dev/null
	@python3 scripts/coverage-report.py "$$(cd $(DOMAIN) && swift test --show-codecov-path)"

.PHONY: coverage-gate
coverage-gate: ## Fail if the domain drops below 95%
	cd $(DOMAIN) && swift test --enable-code-coverage >/dev/null
	@python3 scripts/coverage-report.py "$$(cd $(DOMAIN) && swift test --show-codecov-path)" --gate 95

.PHONY: run
run: build ## Install and launch on the simulator
	xcrun simctl boot $(SIM) 2>/dev/null || true
	xcrun simctl install $(SIM) $(DERIVED)/Build/Products/Debug-iphonesimulator/Tender.app
	xcrun simctl launch $(SIM) ng.tender.app

# --- documentation ----------------------------------------------------------

.PHONY: adr
adr: ## Scaffold the next ADR:  make adr T="the decision"
	@scripts/new-adr.sh "$(T)"

.PHONY: journal
journal: ## Add a session entry:  make journal T="what this session was about"
	@scripts/journal.sh "$(T)"

.PHONY: hooks
hooks: ## Install the git hooks
	@git config core.hooksPath .githooks
	@echo "\033[0;32m✓\033[0m hooks installed (core.hooksPath = .githooks)"

.PHONY: phase
phase: ## Print the current phase and its exit gate
	@p=$$(cat PHASE); \
	echo "Phase $$p"; \
	awk -v want="## Phase $$p" '$$0 ~ want {inside=1} /^## Phase/ && $$0 !~ want {inside=0} inside' docs/ROADMAP.md \
	  | grep -A6 '^\*\*Exit gate\*\*' || true
