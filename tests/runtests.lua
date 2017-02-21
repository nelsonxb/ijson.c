local ffi = require('ffi')

ffi.cdef(io.open('ijson.h'):read('*a'))
ffi.cdef [[
void *malloc(size_t size);
void free(void *ptr);
]]

ffi.ijson = ffi.load('./ijson.so')

local microtest = require('microtest')

microtest.require('stream')
microtest.require('document')

microtest.run()
microtest.report()
