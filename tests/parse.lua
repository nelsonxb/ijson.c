local ffi = require('ffi')
local C = ffi.C
local lib = ffi.ijson

local microtest = require('microtest')

c('parser', function()
    microtest.require('parse-tfn')
end)
