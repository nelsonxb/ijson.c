
test: ijson.so ijson.h
	luajit test.lua
.PHONY: test


ijson.h: ../ijson.h
	$(CC) -o $@ -E $^

ijson.so: ijson.o
ijson.o: ../ijson.c ../ijson.h

