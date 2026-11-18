SRC_DIR = src

# the `-Wno`s quiet C90 warnings
PG_CFLAGS = -std=c11 -Wextra -Wall -Werror \
	-Wno-declaration-after-statement \
	-Wno-vla \
	-Wno-long-long
ifeq ($(COVERAGE), 1)
PG_CFLAGS += --coverage
endif

ifeq ($(CC),gcc)
  GCC_MAJ := $(firstword $(subst ., ,$(shell $(CC) -dumpfullversion -dumpversion)))
  GCC_GE14 = $(shell test $(GCC_MAJ) -ge 14; echo $$?)
  ifeq ($(GCC_GE14),0)
    PG_CFLAGS += -Wmissing-variable-declarations
  endif
endif

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
    SHARED_EXT  := dylib
else
    SHARED_EXT  := so
endif

TESTS = $(wildcard test/sql/*.sql)
REGRESS = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = --use-existing --inputdir=test

MODULE_big = pathological
SRC = $(wildcard $(SRC_DIR)/*.c)

ifdef BUILD_DIR
OBJS = $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o, $(SRC))
else
OBJS = $(patsubst $(SRC_DIR)/%.c, src/%.o, $(SRC)) # if no BUILD_DIR, just build on src so standard PGXS `make` works
endif

PG_CONFIG = pg_config

PG_CPPFLAGS := $(CPPFLAGS)

all:

build: $(BUILD_DIR)/$(MODULE_big).$(SHARED_EXT)

$(BUILD_DIR)/.gitignore:
	mkdir -p $(BUILD_DIR)
	echo "*" > $(BUILD_DIR)/.gitignore

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c $(BUILD_DIR)/.gitignore
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/$(MODULE_big).$(SHARED_EXT): $(MODULE_big).$(SHARED_EXT)
	mv $? $@

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

.PHONY: test
test:
	make installcheck

.PHONY: test-core
test-core:
	$(pg_regress_installcheck) --dlpath=$(PG_REGRESS_TESTS)/lib --inputdir=$(PG_REGRESS_TESTS) --schedule=$(PG_REGRESS_TESTS)/parallel_schedule --dbname=regression
