# Makefile for this Nix / Home Manager dotfiles repo.
#
# Auto-detects the platform and uses the right workflow:
#   - Linux  -> standalone Home Manager (`home-manager switch`)
#   - macOS  -> nix-darwin (`sudo darwin-rebuild switch`, system + Home Manager)
#
# Run targets from the repo root, e.g. `make switch`, `make dry-run`.

# pkgs-diff uses bash process substitution.
SHELL := bash

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Linux)
  PLATFORM := linux
  HOST     := linux
else ifeq ($(UNAME_S),Darwin)
  PLATFORM := darwin
  HOST     := mac
else
  $(error Unsupported platform: $(UNAME_S))
endif

# '#' starts a comment in Makefiles, so route the flake-attr separator through
# a variable (introduced at expansion time, after comment stripping).
HASH       := \#
FLAKE      := .
ACTIVATION := $(FLAKE)$(HASH)homeConfigurations.$(HOST).activationPackage

# Default to a safe, informational action: build + dry-run activation (applies
# nothing). Run `make help` to list targets, `make switch` to apply.
.DEFAULT_GOAL := dry-run

.PHONY: help switch build dry-run check update update-switch rollback generations pkgs pkgs-diff

help: ## Show this help
	@echo "Platform: $(UNAME_S) -> host '$(HOST)' ($(PLATFORM))"
	@echo
	@echo "Targets:"
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

switch: ## Build and activate the config for this machine
ifeq ($(PLATFORM),linux)
	home-manager switch --flake $(FLAKE)$(HASH)$(HOST)
else
	sudo darwin-rebuild switch --flake $(FLAKE)$(HASH)$(HOST)
endif

build: ## Build the activation package (no changes applied)
	nix build $(ACTIVATION)

dry-run: build ## Build, then dry-run activation, applies nothing (default)
	DRY_RUN=1 VERBOSE=1 ./result/activate

check: ## Sanity-check both hosts (build native, eval the other)
	nix/check.sh

update: ## Update all flake inputs (rewrites flake.lock)
	nix flake update

update-switch: update switch ## Update flake inputs, then switch

rollback: ## Roll back to the previous generation
ifeq ($(PLATFORM),linux)
	home-manager switch --rollback
else
	sudo darwin-rebuild --rollback
endif

generations: ## List Home Manager generations
	home-manager generations

pkgs: ## (Linux) Install curated official-repo + AUR bootstrap packages
ifeq ($(PLATFORM),linux)
	sudo pacman -S --needed - < linux/packages.txt
	@command -v paru >/dev/null 2>&1 && paru -S --needed - < linux/aur.txt \
		|| { command -v yay >/dev/null 2>&1 && yay -S --needed - < linux/aur.txt; } \
		|| echo "No AUR helper (paru/yay) found; skipping linux/aur.txt"
else
	@echo "pkgs: Linux-only (macOS packages are declared via nix-darwin Homebrew)"
endif

pkgs-diff: ## (Linux) Show explicitly-installed packages not in the curated lists
ifeq ($(PLATFORM),linux)
	@echo "# official-repo installed but not in linux/packages.txt:"
	@comm -23 <(pacman -Qqen | sort) <(grep -v '^#' linux/packages.txt | grep -v '^$$' | sort -u)
	@echo "# AUR installed but not in linux/aur.txt:"
	@comm -23 <(pacman -Qqem | sort) <(grep -v '^#' linux/aur.txt | grep -v '^$$' | sort -u)
else
	@echo "pkgs-diff: Linux-only"
endif
