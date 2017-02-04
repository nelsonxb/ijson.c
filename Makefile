
all: test
.PHONY: all test clean
test: ijson_test
	ijson_test
clean:
	rm -rvf *.o ijson_test

ijson.o: ijson.h
ijson_test.o: ijson.h
ijson_test: ijson.o
