
all: test
.PHONY: all test
test: ijson.c ijson.h
	$(MAKE) -C tests test
