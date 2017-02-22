local ffi = require('ffi')
local C = ffi.C
local lib = ffi.ijson

c('whitepace', function()
    t('null parses correctly with leading spaces', function()
        local doc = ffi.gc(ffi.new('struct ijson_document'),
                           lib.ijson_doc_release)
        lib.ijson_doc_init(doc, 8)
        lib.ijson_doc_data(doc, 8, '    null')

        local state = lib.ijson_start(doc)
        assert(state ~= nil, 'state should not be NULL')
        assert.n.eq('status', state.status, 'IJSON_OK')
        assert(state.token ~= nil, 'token should not be NULL')
        assert.n.eq('token type', state.token.info.type, 'IJSON_VALUE_NULL')
    end)

    t('null parses correctly with leading tab', function()
        local doc = ffi.gc(ffi.new('struct ijson_document'),
                           lib.ijson_doc_release)
        lib.ijson_doc_init(doc, 8)
        lib.ijson_doc_data(doc, 5, '\tnull')

        local state = lib.ijson_start(doc)
        assert(state ~= nil, 'state should not be NULL')
        assert.n.eq('status', state.status, 'IJSON_OK')
        assert(state.token ~= nil, 'token should not be NULL')
        assert.n.eq('token type', state.token.info.type, 'IJSON_VALUE_NULL')
    end)

    t('null parses correctly with leading newline', function()
        local doc = ffi.gc(ffi.new('struct ijson_document'),
                           lib.ijson_doc_release)
        lib.ijson_doc_init(doc, 8)
        lib.ijson_doc_data(doc, 5, '\nnull')

        local state = lib.ijson_start(doc)
        assert(state ~= nil, 'state should not be NULL')
        assert.n.eq('status', state.status, 'IJSON_OK')
        assert(state.token ~= nil, 'token should not be NULL')
        assert.n.eq('token type', state.token.info.type, 'IJSON_VALUE_NULL')
    end)

    t('null parses correctly with leading CR', function()
        local doc = ffi.gc(ffi.new('struct ijson_document'),
                           lib.ijson_doc_release)
        lib.ijson_doc_init(doc, 8)
        lib.ijson_doc_data(doc, 5, '\rnull')

        local state = lib.ijson_start(doc)
        assert(state ~= nil, 'state should not be NULL')
        assert.n.eq('status', state.status, 'IJSON_OK')
        assert(state.token ~= nil, 'token should not be NULL')
        assert.n.eq('token type', state.token.info.type, 'IJSON_VALUE_NULL')
    end)
end)
