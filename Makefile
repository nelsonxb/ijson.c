
all: test
.PHONY: all test
test:
	$(MAKE) -C tests test
