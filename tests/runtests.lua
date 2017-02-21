local ffi = require('ffi')
ffi.cdef(io.open('ijson.h'):read('*a'))
ffi.ijson = ffi.load('./ijson.so')

local microtest = require('microtest')

microtest.require('stream')
microtest.run()
microtest.report()
