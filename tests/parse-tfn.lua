local ffi = require('ffi')
local C = ffi.C
local lib = ffi.ijson

c('bool and null', function()
    t('null parses correctly', function()
        local doc = ffi.gc(ffi.new('struct ijson_document'),
                           lib.ijson_doc_release)
        lib.ijson_doc_init(doc, 8)
        lib.ijson_doc_data(doc, 4, 'null')

        local state = lib.ijson_start(doc)
        assert(state ~= nil, 'state should not be NULL')
        assert.n.eq('status', state.status, 'IJSON_OK')
        assert(state.token ~= nil, 'token should not be NULL')
        assert.n.eq('token type', state.token.info.type, 'IJSON_VALUE_NULL')
    end)

    t('part-null gives error', function()
        local doc = ffi.gc(ffi.new('struct ijson_document'),
                           lib.ijson_doc_release)
        lib.ijson_doc_init(doc, 8)
        lib.ijson_doc_data(doc, 4, 'nuul')

        local state = lib.ijson_start(doc)
        assert(state ~= nil, 'state should not be NULL')
        assert.n.eq('status', state.status, 'IJSON_UNEXPECTED')
        assert(state.token ~= nil, 'token should not be NULL')
        assert.n.eq('token type', state.token.info.type, 'IJSON_VALUE_NULL')
    end)

    t('true parses correctly', function()
        local doc = ffi.gc(ffi.new('struct ijson_document'),
                           lib.ijson_doc_release)
        lib.ijson_doc_init(doc, 8)
        lib.ijson_doc_data(doc, 4, 'true')

        local state = lib.ijson_start(doc)
        assert(state ~= nil, 'state should not be NULL')
        assert.n.eq('status', state.status, 'IJSON_OK')
        assert(state.token ~= nil, 'token should not be NULL')
        assert.n.eq('token type', state.token.info.type, 'IJSON_VALUE_BOOLEAN')
        assert.n.ne('boolean value', state.token.integer.data, 0)
    end)

    t('part-true gives error', function()
        local doc = ffi.gc(ffi.new('struct ijson_document'),
                           lib.ijson_doc_release)
        lib.ijson_doc_init(doc, 8)
        lib.ijson_doc_data(doc, 4, 'ture')

        local state = lib.ijson_start(doc)
        assert(state ~= nil, 'state should not be NULL')
        assert.n.eq('status', state.status, 'IJSON_UNEXPECTED')
        assert(state.token ~= nil, 'token should not be NULL')
        assert.n.eq('token type', state.token.info.type, 'IJSON_VALUE_BOOLEAN')
        assert.n.ne('boolean value', state.token.integer.data, 0)
    end)

    t('false parses correctly', function()
        local doc = ffi.gc(ffi.new('struct ijson_document'),
                           lib.ijson_doc_release)
        lib.ijson_doc_init(doc, 8)
        lib.ijson_doc_data(doc, 5, 'false')

        local state = lib.ijson_start(doc)
        assert(state ~= nil, 'state should not be NULL')
        assert.n.eq('status', state.status, 'IJSON_OK')
        assert(state.token ~= nil, 'token should not be NULL')
        assert.n.eq('token type', state.token.info.type, 'IJSON_VALUE_BOOLEAN')
        assert.n.eq('boolean value', state.token.integer.data, 0)
    end)

    t('part-false gives error', function()
        local doc = ffi.gc(ffi.new('struct ijson_document'),
                           lib.ijson_doc_release)
        lib.ijson_doc_init(doc, 8)
        lib.ijson_doc_data(doc, 4, 'fase')

        local state = lib.ijson_start(doc)
        assert(state ~= nil, 'state should not be NULL')
        assert.n.eq('status', state.status, 'IJSON_UNEXPECTED')
        assert(state.token ~= nil, 'token should not be NULL')
        assert.n.eq('token type', state.token.info.type, 'IJSON_VALUE_BOOLEAN')
        assert.n.eq('boolean value', state.token.integer.data, 0)
    end)
end)
