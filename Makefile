PROJECT_NAME = Nydus Test

SOURCES := \
  $(shell find . 2>&1 | grep -E '.*\.rs$$') \
  Cargo.toml

ARCH = $(shell uname -m)
LIBC = musl
TRIPLE = $(ARCH)-unknown-linux-$(LIBC)

optimize: $(SOURCES) | show-summary show-header
	@RUSTFLAGS='-C link-arg=-s' cargo build --target $(TRIPLE) --$(BUILD_TYPE)

$(GENERATED_FILES): %: %.in
	@sed $(foreach r,$(GENERATED_REPLACEMENTS),-e 's|@$r@|$($r)|g') "$<" > "$@"

show-header:
	@printf "%s - version %s (commit %s)\n\n" "$(TARGET)" "$(VERSION_COMMIT)" "$(COMMIT_MSG)"

install:
	@install -D $(TARGET_PATH) $(DESTDIR)/$(BINDIR)/$(TARGET)

clean:
	@cargo clean
	@rm -f $(GENERATED_FILES)

clippy:
	@cargo clippy --all-targets --all-features -- -D warnings

run:
	@cargo run --target $(TRIPLE)

show-summary: show-header
	@printf "project:\n"
	@printf "  name: $(PROJECT_NAME)\n"
	@printf "target: $(TARGET)\n"
	@printf "architecture:\n"
	@printf "  host: $(ARCH)\n"
	@printf "rust:\n"
	@printf "  %s\n" "$(call get_command_version,cargo)"
	@printf "  %s\n" "$(call get_command_version,rustc)"
	@printf "  %s\n" "$(call get_command_version,rustup)"
	@printf "  %s\n" "$(call get_toolchain_version)"
	@printf "\n"

help: show-summary

.PHONY: \
	help \
	show-header \
	show-summary \
	optimize