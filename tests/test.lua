local ffi = require('ffi')

ffi.load('./ijson.so', true)

local hf = io.open('ijson.h')
ffi.cdef(hf:read('*a'))
hf:close()

t = {}

local function test(module, modname)
    local result = nil
    if type(module) == 'string' then
        local m = require(module)
        result = test(m, module)
    elseif type(module) == 'function' then
        t.name = modname
        result = module(ffi.C)
        t.name = nil
    else
        result = {}
        for n, t in pairs(module) do
            result[n] = test(t, modname .. '.' .. n)
        end
    end

    return result
end

test('basic')
