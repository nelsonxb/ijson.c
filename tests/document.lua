local ffi = require('ffi')
local C = ffi.C
local lib = ffi.ijson

c('document', function()
    c('initializer', function()
        t('initializes fields', function()
            local doc = ffi.gc(ffi.new('ijson_document'),
                               lib.ijson_doc_release)

            lib.ijson_doc_init(doc, 256)
            assert.n.eq('stream length', doc.data.stream_length, 0)
            assert.n.eq('block size', doc.data.node_length, 256)

            assert.n.eq('root state', doc.root_state, nil)
        end)
    end)

    c('data', function()
        t('puts data in stream', function()
            local doc = ffi.gc(ffi.new('ijson_document'),
                               lib.ijson_doc_release)
            lib.ijson_doc_init(doc, 4)
            local data = 'foo bar baz qux'

            lib.ijson_doc_data(doc, #data, data)

            assert.n.eq('stream length', doc.data.stream_length, #data)

            local actual = lib.ijson__stream_substr(doc.data, 0, -1)
            ffi.gc(actual, C.free)
            actual = ffi.string(actual, doc.data.stream_length)
            assert.n.eq('stream content', actual, data)
        end)

        t('appends data to stream', function()
            local doc = ffi.gc(ffi.new('ijson_document'),
                               lib.ijson_doc_release)
            lib.ijson_doc_init(doc, 4)
            local data = { 'foo bar', ' baz qux' }
            local fulldata = data[1] .. data[2]

            lib.ijson_doc_data(doc, #data[1], data[1])
            assert.n.eq('stream length before', doc.data.stream_length, #data[1])

            lib.ijson_doc_data(doc, #data[2], data[2])

            assert.n.eq('stream length after', doc.data.stream_length, #fulldata)

            local actual = lib.ijson__stream_substr(doc.data, 0, -1)
            ffi.gc(actual, C.free)
            actual = ffi.string(actual, doc.data.stream_length)
            assert.n.eq('final stream content', actual, fulldata)
        end)
    end)
end)
