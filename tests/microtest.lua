local microtest = {}
setmetatable(microtest, microtest)

function microtest.__call(_, fn, ...)
    local prev = {
        context = microtest._current,   -- only stored to ensure consistency
        c = _G.c, t = _G.t
    }
    _G.c = microtest.context
    _G.t = microtest.test

    local function done(...)
        microtest._current = prev.context
        _G.c = prev.c
        _G.t = prev.t
        return ...
    end

    if fn then
        return done(fn(...))
    else
        return done
    end
end

function microtest.run(pattern)
    local result = microtest._context:run(pattern)
    print()
    return result
end

function microtest.require(modname)
    return microtest(require, modname)
end

function microtest.report()
    local results = microtest._context.results

    print(
        results.passed .. ' tests passed',
        results.failed .. ' tests failed',
        results.errored .. ' errors',
        results.skipped .. ' tests skipped'
    )
    print()

    for i, resinfo in ipairs(results) do
        local test, result = resinfo.test, resinfo.result
        local function fmt(...) return string.format('', ...) end
        if result.error then
            print(i .. ' ERROR', test.fulldesc)
            print(result.error)
            print()
        elseif #result.failures > 0 then
            print(i .. ' FAIL ', test.fulldesc)
            for j, msg in ipairs(result.failures) do
                print(msg)
            end
            print()
        end
    end
end


local function newStatus()
    return { skipped = false, passes = {}, failures = {}, error = nil }
end


local default_assert = assert
local function newAssert(self)
    local assert = {}
    setmetatable(assert, assert)
    function assert:__call(...) return default_assert(...) end

    local function ax(b, m, d)
        if not m then m = d end
        return self:assert(b, m)
    end

    local function ts(v)
        if type(v) == 'string' then
            return string.format('%q', v)
        else
            return tostring(v)
        end
    end

    local function nm(n, v, d)
        if not n then
            return ts(v) .. ' ' .. d
        else
            return n .. ' (' .. ts(v) .. ') ' .. d
        end
    end

    assert.n = {}
    function assert.n.t(n, b, msg)
        return ax(b, msg, nm(n, b, 'should be truthy'))
    end
    function assert.n.f(n, b, msg)
        return ax(not b, msg, nm(n, b, 'should be falsy'))
    end
    function assert.n.eq(n, a, e, msg)
        return ax(a == e, msg, nm(n, a, 'should equal ' .. ts(e)))
    end
    function assert.n.ne(n, a, e, msg)
        return ax(a ~= e, msg, nm(n, a, 'should not equal ' .. ts(e)))
    end

    function assert.t(b, msg) return assert.n.t(nil, b, msg) end
    function assert.f(b, msg) return assert.n.f(nil, b, msg) end
    function assert.eq(a, e, msg) return assert.n.eq(nil, a, e, msg) end
    function assert.ne(a, e, msg) return assert.n.ne(nil, a, e, msg) end

    return assert
end


local Context = {}
Context.__index = Context

local function newContext(ctx, desc, chunk, skip)
    local self = {}
    setmetatable(self, Context)
    self.children = {}

    if ctx == nil then
        self.results = {
            skipped = 0, errored = 0, failed = 0, passed = 0,
            mention = {}
        }
        return self
    end
    self.context = ctx
    table.insert(ctx.children, self)
    self.desc = desc
    if ctx.fulldesc == nil then
        self.fulldesc = desc
    else
        self.fulldesc = ctx.fulldesc .. ' ' .. desc
    end
    self.skip = skip or ctx.skip

    local prev = microtest._current
    microtest._current = self
    chunk()
    microtest._current = prev

    return self
end

function Context:run(pattern)
    for i, child in ipairs(self.children) do
        if child.children then
            child:run()
        elseif pattern == nil or child.fulldesc:match(pattern) then
            self:result(child, child:run())
        end
    end
end

function Context:result(test, result)
    if self.context then return self.context:result(test, result) end

    local results = self.results
    local resinfo = { test = test, result = result }
    table.insert(results, resinfo)
    if result.skipped then
        results.skipped = results.skipped + 1
    elseif result.error then
        results.errored = results.errored + 1
        table.insert(results.mention, resinfo)
    elseif #result.failures > 0 then
        results.failed = results.failed + 1
        table.insert(results.mention, resinfo)
    else
        results.passed = results.passed + 1
    end
end


local Test = {}
Test.__index = Test

local function newTest(ctx, desc, chunk, skip)
    local self = {}
    setmetatable(self, Test)
    self.context = ctx
    table.insert(ctx.children, self)
    self.desc = desc
    self.fulldesc = ctx.fulldesc .. ' ' .. desc
    self.status = nil
    self.chunk = chunk
    self.skip = skip or ctx.skip
    return self
end

function Test:run()
    if self.status then return self.status end

    local status = newStatus()
    self.status = status

    if self.skip then
        status.skipped = true
        return status
    end

    local prev_assert = _G.assert
    _G.assert = newAssert(self)
    local ok, msg = xpcall(self.chunk, debug.traceback)
    _G.assert = prev_assert

    if not ok then
        status.error = msg
        io.stdout:write('!')
    end

    return status
end

function Test:assert(b, msg)
    local status = self.status
    if b then
        table.insert(status.passes, msg)
        io.stdout:write('.')
    else
        table.insert(status.failures, msg)
        io.stdout:write('x')
    end
end


microtest.context = {}
setmetatable(microtest.context, microtest.context)
function microtest.context.__call(_, desc, chunk)
    return newContext(microtest._current, desc, chunk, false)
end
function microtest.context.skip(desc, chunk)
    return newContext(microtest._current, desc, chunk, true)
end

microtest.test = {}
setmetatable(microtest.test, microtest.test)
function microtest.test.__call(_, desc, chunk)
    return newTest(microtest._current, desc, chunk, false)
end
function microtest.test.skip(desc, chunk)
    return newTest(microtest._current, desc, chunk, true)
end

microtest._context = newContext()
microtest._current = microtest._context
return microtest
