# === Compiler & base flags ===
CXX      := g++
CXXFLAGS := -std=c++17 -Wall -Wextra -Iinclude -MMD -MP
LDFLAGS  :=

# === Build type: make BUILD=Release (default Debug) ===
BUILD ?= Debug
ifeq ($(BUILD),Debug)
  CXXFLAGS += -O0 -g -DDEBUG
else ifeq ($(BUILD),Release)
  CXXFLAGS += -O3 -DNDEBUG
else
  $(error BUILD must be Debug or Release)
endif

# --- Sanitizers: enable with SAN=1 ---
ifeq ($(SAN),1)
  CXXFLAGS += -fsanitize=address,undefined -fno-omit-frame-pointer -O1 -g
  LDFLAGS  += -fsanitize=address,undefined
endif

# --- Coverage flags (used when COVERAGE=1) ---
ifeq ($(COVERAGE),1)
  CXXFLAGS += --coverage -O0 -g
  LDFLAGS  += --coverage
endif

# === Generic pkg-config support (optional) ===
# Use like: make PKGS="gtk+-3.0 glib-2.0"
PKG_CONFIG ?= pkg-config
PKGS ?=
ifneq ($(strip $(PKGS)),)
  ifeq ($(shell $(PKG_CONFIG) --exists $(PKGS) && echo yes),yes)
    CXXFLAGS += $(shell $(PKG_CONFIG) --cflags $(PKGS))
    LDFLAGS  += $(shell $(PKG_CONFIG) --libs   $(PKGS))
  else
    $(warning One or more PKGS not found via pkg-config: '$(PKGS)')
  endif
endif

# === gcovr binary for coverage (can override: make GCOVR="python3 -m gcovr") ===
GCOVR ?= gcovr

# === Colours ===
ifndef NO_COLOR
  RESET   := \033[0m
  BOLD    := \033[1m
  BLUE    := \033[34m
  GREEN   := \033[32m
  YELLOW  := \033[33m
  MAGENTA := \033[35m
  RED     := \033[31m
  CYAN    := \033[36m
else
  RESET:= ; BOLD:= ; BLUE:= ; GREEN:= ; YELLOW:= ; MAGENTA:= ; RED:= ; CYAN:=
endif

# Pretty printers
msg_cxx   = printf "$(BOLD)$(BLUE)[ CXX ]$(RESET) %s  -> %s\n" "$(1)" "$(2)"
msg_link  = printf "$(BOLD)$(GREEN)[ LINK]$(RESET) %s\n" "$(1)"
msg_ar    = printf "$(BOLD)$(GREEN)[  AR ]$(RESET) %s\n" "$(1)"
msg_test  = printf "$(BOLD)$(MAGENTA)[ TEST]$(RESET) %s\n" "$(1)"
msg_pass  = printf "$(BOLD)$(GREEN)[ PASS]$(RESET) %s\n" "$(1)"
msg_fail  = printf "$(BOLD)$(RED)[ FAIL]$(RESET)  %s (exit %d)\n" "$(1)" "$(2)"
msg_clean = printf "$(BOLD)$(YELLOW)[CLEAN]$(RESET) %s\n" "$(1)"
msg_cov   = printf "$(BOLD)$(CYAN)[COVER]$(RESET) %s\n" "$(1)"

# === Dirs ===
SRC_DIR    := src
LIB_DIR    := $(SRC_DIR)/lib
INC_DIR    := include
BUILD_DIR  := build
BUILD_LIB  := $(BUILD_DIR)/lib
BIN_DIR    := bin
TEST_DIR   := tests
TEST_BUILD := $(BUILD_DIR)/tests
TEST_BIN   := $(BIN_DIR)/tests

TARGET     := $(BIN_DIR)/myprogram
STATIC_LIB := $(BUILD_LIB)/libapp.a

# === Discover sources ===
ALL_SRCS := $(shell find $(SRC_DIR) -name '*.cpp' 2>/dev/null)
LIB_SRCS := $(shell test -d $(LIB_DIR) && find $(LIB_DIR) -name '*.cpp' 2>/dev/null || echo)
APP_SRCS := $(filter-out $(LIB_SRCS),$(ALL_SRCS))

ALL_OBJS := $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/%.o,$(ALL_SRCS))
LIB_OBJS := $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/%.o,$(LIB_SRCS))
APP_OBJS := $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/%.o,$(APP_SRCS))
MAIN_OBJS := $(filter %/main.o $(BUILD_DIR)/main.o,$(APP_OBJS))
APP_OBJS_NO_MAIN := $(filter-out $(MAIN_OBJS),$(APP_OBJS))
DEPS := $(ALL_OBJS:.o=.d)

# === Tests ===
TEST_SRCS := $(shell test -d $(TEST_DIR) && find $(TEST_DIR) -name '*.cpp' 2>/dev/null || echo)
TEST_OBJS := $(patsubst $(TEST_DIR)/%.cpp,$(TEST_BUILD)/%.o,$(TEST_SRCS))
TEST_BINS := $(patsubst $(TEST_BUILD)/%.o,$(TEST_BIN)/%,$(TEST_OBJS))

.PHONY: all
all: $(TARGET)

# Static library from src/lib/**
$(STATIC_LIB): $(LIB_OBJS) | $(BUILD_LIB)
	@$(call msg_ar,$@)
	@ar rcs $@ $(LIB_OBJS)

# Link app
$(TARGET): $(APP_OBJS) $(STATIC_LIB) | $(BIN_DIR)
	@$(call msg_link,$@)
	@$(CXX) $(CXXFLAGS) $(APP_OBJS) -L$(BUILD_LIB) -lapp $(LDFLAGS) -o $@

# Compile sources
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	@$(call msg_cxx,$<,$@)
	@$(CXX) $(CXXFLAGS) -c $< -o $@

# Compile tests
$(TEST_BUILD)/%.o: $(TEST_DIR)/%.cpp | $(TEST_BUILD)
	@mkdir -p $(dir $@)
	@$(call msg_cxx,$<,$@)
	@$(CXX) $(CXXFLAGS) -c $< -o $@

# Link tests
$(TEST_BIN)/%: $(TEST_BUILD)/%.o $(APP_OBJS_NO_MAIN) $(STATIC_LIB) | $(TEST_BIN)
	@$(call msg_link,$@)
	@$(CXX) $(CXXFLAGS) $^ -L$(BUILD_LIB) -lapp $(LDFLAGS) -o $@

# Run tests
.PHONY: test
test: $(TEST_BINS)
	@set -e; failures=0; total=0; \
	for t in $(TEST_BINS); do \
	  $(call msg_test,$$t); \
	  if "$$t"; then \
	    $(call msg_pass,$$t); \
	  else \
	    code=$$?; failures=$$((failures+1)); \
	    $(call msg_fail,$$t,$$code); \
	  fi; \
	  total=$$((total+1)); \
	done; \
	printf "$(BOLD)$(CYAN)[ SUMM]$(RESET) Ran %d test binary(ies): " $$total; \
	if [ $$failures -eq 0 ]; then \
	  printf "$(GREEN)%s passed$(RESET)\n" $$total; \
	else \
	  printf "$(RED)%s failed$(RESET)\n" $$failures; \
	fi; \
	test $$failures -eq 0

# Coverage (requires gcovr; this target forces a fresh instrumented build)
.PHONY: coverage coverage-html
coverage:
	@$(MAKE) clean
	@$(MAKE) BUILD=Debug COVERAGE=1 test
	@command -v $(GCOVR) >/dev/null 2>&1 || { \
	  echo "gcovr not found. Install it (e.g. 'pip install gcovr') to see coverage output."; \
	  exit 0; \
	}; \
	$(call msg_cov,Summary); \
	$(GCOVR) --root . --filter src --filter include --exclude 'tests/.*' --print-summary

coverage-html:
	@$(MAKE) clean
	@$(MAKE) BUILD=Debug COVERAGE=1 test
	@command -v $(GCOVR) >/dev/null 2>&1 || { \
	  echo "gcovr not found. Install it (e.g. 'pip install gcovr') to see coverage output."; \
	  exit 0; \
	}; \
	mkdir -p coverage; \
	$(call msg_cov,HTML -> coverage/index.html); \
	$(GCOVR) --root . --filter src --filter include --exclude 'tests/.*' --html --html-details -o coverage/index.html; \
	printf "\nOpen ./coverage/index.html in your browser.\n"

# pkg-config helpers
.PHONY: pkgs-list pkg-flags
pkgs-list:
	@echo "$(BOLD)Installed pkg-config packages:$(RESET)"
	@$(PKG_CONFIG) --list-all 2>/dev/null | sort || echo "pkg-config not found."

pkg-flags:
	@if [ -z "$(PKGS)" ]; then echo "Usage: make pkg-flags PKGS=\"<pkg1> [pkg2 ...]\""; exit 1; fi
	@echo "$(BOLD)CFLAGS:$(RESET) $$($(PKG_CONFIG) --cflags $(PKGS))"
	@echo "$(BOLD)LIBS:  $(RESET) $$($(PKG_CONFIG) --libs   $(PKGS))"

# Ensure dirs
$(BUILD_DIR) $(BUILD_LIB) $(BIN_DIR) $(TEST_BUILD) $(TEST_BIN):
	@mkdir -p $@

.PHONY: run
run: $(TARGET)
	@./$(TARGET)

.PHONY: clean
clean:
	@$(call msg_clean,$(BUILD_DIR), $(TARGET), $(TEST_BIN), coverage)
	@rm -rf $(BUILD_DIR) $(TARGET) $(TEST_BIN) coverage
	@find . -name '*.gcno' -o -name '*.gcda' 2>/dev/null | xargs -r rm -f

-include $(DEPS)
