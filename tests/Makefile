
test: ijson.so ijson.h
	luajit runtests.lua
.PHONY: test


ijson.h: ../ijson.h
	$(CC) -E $^ | grep -v '^#' >$@

ijson.so: ijson.o
	$(CC) -shared $(LDFLAGS) -o $@ $^ $(LOADLIBES) $(LDLIBS)
ijson.o: ../ijson.c ../ijson.h
	$(CC) -fPIC $(CPPFLAGS) $(CFLAGS) -o $@ -c $<

