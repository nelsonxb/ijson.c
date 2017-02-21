local ffi = require('ffi')
local C = ffi.C
local lib = ffi.ijson

c('stream', function()
    c('initalizer', function()
        t('initializes fields', function()
            local stream = ffi.new('struct ijson__stream')
            lib.ijson__stream_init(stream, 256)
            assert.n.eq('stream length', stream.stream_length, 0)
            assert.n.eq('first node', stream.first, nil)
            assert.n.eq('last node', stream.last, nil)
        end)

        t('sets node length', function()
            local stream = ffi.new('struct ijson__stream')
            lib.ijson__stream_init(stream, 256)
            assert.n.eq('node length', stream.node_length, 256)
        end)
    end)

    c('creator', function()
        t('creates new stream', function()
            local stream = ffi.gc(lib.ijson__stream_new(256),
                                  lib.ijson__stream_free)
            assert.n.ne('stream', stream, nil)
            assert.t(ffi.istype('struct ijson__stream', stream),
                'stream type should be `struct ijson__stream`')
        end)

        t('initializes stream', function()
            local stream = ffi.gc(lib.ijson__stream_new(256),
                                  lib.ijson__stream_free)
            assert.n.eq('stream length', stream.stream_length, 0)
            assert.n.eq('node length', stream.node_length, 256)
            assert.n.eq('first node', stream.first, nil)
            assert.n.eq('last node', stream.last, nil)
        end)
    end)

    c('append', function()
        t('writes one full block', function()
            local stream = ffi.gc(lib.ijson__stream_new(8),
                                  lib.ijson__stream_free)
            local data = 'abcdefgh'
            lib.ijson__stream_append(stream, 8, data)

            assert.n.eq('stream length', stream.stream_length, 8)
            assert.n.ne('first node', stream.first, nil)
            assert.n.eq('last node', stream.last, stream.first)
            assert.n.eq('stream data', ffi.string(stream.first.data, 8), data)
        end)

        t('writes one part block', function()
            local stream = ffi.gc(lib.ijson__stream_new(8),
                                  lib.ijson__stream_free)
            local data = 'abcdef'
            lib.ijson__stream_append(stream, 6, data)

            assert.n.eq('stream length', stream.stream_length, 6)
            assert.n.ne('first node', stream.first, nil)
            assert.n.eq('last node', stream.last, stream.first)
            assert.n.eq('stream data', ffi.string(stream.first.data, 6), data)
        end)

        t('writes multiple blocks', function()
            local stream = ffi.gc(lib.ijson__stream_new(8),
                                  lib.ijson__stream_free)
            local data = 'abcdefabcdef'
            lib.ijson__stream_append(stream, 12, data)

            assert.n.eq('stream length', stream.stream_length, 12)
            assert.n.ne('first node', stream.first, nil)
            assert.n.ne('last node', stream.last, nil)
            assert.n.ne('last node', stream.last, stream.first)

            assert.n.eq('first node length', stream.first.clength, 8)
            assert.n.eq('last node length', stream.last.clength, 4)
            assert.n.eq('first node data',
                ffi.string(stream.first.data, 8), 'abcdefab')
            assert.n.eq('last node data',
                ffi.string(stream.last.data, 4), 'cdef')
        end)

        t('adds one full block', function()
            local stream = ffi.gc(lib.ijson__stream_new(8),
                                  lib.ijson__stream_free)
            local data = 'abcdefgh'
            lib.ijson__stream_append(stream, 8, '12345678')

            lib.ijson__stream_append(stream, 8, data)
            assert.n.eq('stream length', stream.stream_length, 16)
            assert.n.ne('last node', stream.last, stream.first)
            assert.n.eq('last node length', stream.last.clength, 8)
            assert.n.eq('last node data',
                ffi.string(stream.last.data, 8), data)
        end)

        t('adds multiple blocks', function()
            local stream = ffi.gc(lib.ijson__stream_new(8),
                                  lib.ijson__stream_free)
            local data = 'abcdefg'
            lib.ijson__stream_append(stream, 6, '123456')

            lib.ijson__stream_append(stream, 6, data)
            assert.n.eq('stream length', stream.stream_length, 12)
            assert.n.ne('last node', stream.last, stream.first)
            assert.n.eq('first node length', stream.first.clength, 8)
            assert.n.eq('last node length', stream.last.clength, 4)
            assert.n.eq('first node data',
                ffi.string(stream.first.data, 8), '123456ab')
            assert.n.eq('last node data',
                ffi.string(stream.last.data, 4), 'cdef')
        end)
    end)

    c('find', function()
        t('locates correct node', function()
            local stream = ffi.gc(lib.ijson__stream_new(4),
                                  lib.ijson__stream_free)
            lib.ijson__stream_append(stream, 13, 'foo bar baz x')
            local node_p = ffi.new('struct ijson__stream_node *[1]')
            local pos_p = ffi.new('size_t [1]')

            lib.ijson__stream_find(stream, 9, node_p, pos_p)
            assert.n.eq('node data', ffi.string(node_p[0].data, 4), 'baz ')
        end)

        t('locates correct position in node', function()
            local stream = ffi.gc(lib.ijson__stream_new(4),
                                  lib.ijson__stream_free)
            lib.ijson__stream_append(stream, 13, 'foo bar baz x')
            local node_p = ffi.new('struct ijson__stream_node *[1]')
            local pos_p = ffi.new('size_t [1]')

            lib.ijson__stream_find(stream, 9, node_p, pos_p)
            assert.n.eq('node pos', pos_p[0], 1)
            assert.n.eq('located data',
                ffi.string(node_p[0].data + pos_p[0], 3), 'az ')
        end)
    end)

    c('flatten', function()
        t('returns empty string', function()
            local stream = ffi.gc(lib.ijson__stream_new(4),
                                  lib.ijson__stream_free)
            local actual = lib.ijson__stream_substr(stream,
                                                  0, stream.stream_length)
            ffi.gc(actual, C.free)
            actual = ffi.string(actual, stream.stream_length)
            assert.n.eq('actual string', actual, '')
        end)

        t('returns correct full string', function()
            local stream = ffi.gc(lib.ijson__stream_new(4),
                                  lib.ijson__stream_free)
            lib.ijson__stream_append(stream, 16, 'foo bar baz qux ')

            local full = lib.ijson__stream_substr(stream,
                                                  0, stream.stream_length)
            ffi.gc(full, C.free)
            full = ffi.string(full, 16)
            assert.n.eq('full string', full, 'foo bar baz qux ')
        end)

        t('returns correct substring', function()
            local stream = ffi.gc(lib.ijson__stream_new(4),
                                  lib.ijson__stream_free)
            lib.ijson__stream_append(stream, 16, 'foo bar baz qux ')

            local sub = lib.ijson__stream_substr(stream, 5, 11)
            ffi.gc(sub, C.free)
            sub = ffi.string(sub, 6)
            assert.n.eq('substring', sub, 'ar baz')
        end)

        t('returns correct full string (negative end)', function()
            local stream = ffi.gc(lib.ijson__stream_new(4),
                                  lib.ijson__stream_free)
            lib.ijson__stream_append(stream, 16, 'foo bar baz qux ')

            local full = lib.ijson__stream_substr(stream, 0, -1)
            ffi.gc(full, C.free)
            full = ffi.string(full, 16)
            assert.n.eq('full string', full, 'foo bar baz qux ')
        end)

        t('returns correct substring (negative start/end)', function()
            local stream = ffi.gc(lib.ijson__stream_new(4),
                                  lib.ijson__stream_free)
            lib.ijson__stream_append(stream, 16, 'foo bar baz qux ')

            local sub = lib.ijson__stream_substr(stream, -12, -6)
            ffi.gc(sub, C.free)
            sub = ffi.string(sub, 6)
            assert.n.eq('substring', sub, 'ar baz')
        end)
    end)
end)
