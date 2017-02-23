/* This file is a part of the ijson library. */
/* See https://github.com/NelsonCrosby/ijson.c */

/********** The ijson library is available under the following terms **********
 * The MIT License (MIT)
 *
 * Copyright (c) 2017, Nelson Crosby <nelsonc@sourcecomb.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *****************************************************************************/


#include <stdlib.h>
#include <string.h>
#include "ijson.h"

void IJSON_(_stream_init)(struct IJSON_(_stream) *stream, size_t node_length)
{
    stream->stream_length = 0;
    stream->node_length = node_length;
    stream->first = NULL;
    stream->last = NULL;
}

struct IJSON_(_stream) *IJSON_(_stream_new)(size_t node_length)
{
    struct IJSON_(_stream) *stream =
        (struct IJSON_(_stream) *) malloc(sizeof(struct IJSON_(_stream)));
    IJSON_(_stream_init)(stream, node_length);
    return stream;
}

void IJSON_(_stream_find)(struct IJSON_(_stream) *stream, size_t idx,
        struct IJSON_(_stream_node) **out_node, size_t *out_idx)
{
    if (idx > stream->stream_length) {
        *out_node = NULL;
        *out_idx = 0;
        return;
    }

    size_t node_idx = idx / stream->node_length;
    *out_idx = idx % stream->node_length;
    struct IJSON_(_stream_node) *node = stream->first;
    for (int i = 0; node && i < node_idx; i += 1) {
        node = node->next;
    }

    if (node == NULL) {
        *out_idx = 0;
    }
    *out_node = node;
}

int IJSON_(_stream_append)(struct IJSON_(_stream) *stream,
        size_t length, const char const *data)
{
    size_t nodelen = stream->node_length;
    struct IJSON_(_stream_node) *last = stream->last;
    size_t pos = 0;

    if (last == NULL) {
        last = (struct IJSON_(_stream_node) *)
            malloc(sizeof(struct IJSON_(_stream_node)));
        last->clength = 0;
        last->prev = NULL;
        last->next = NULL;
        stream->first = last;
        stream->last = last;

        last->data = malloc(sizeof(char) * nodelen);
    }

    {
        size_t cpylen = nodelen - last->clength;
        if (length < cpylen)
            cpylen = length;
        strncpy(last->data + last->clength, data, length);
        last->clength += cpylen;
        stream->stream_length += cpylen;
        length -= cpylen;
        pos += cpylen;
    }

    while (length) {
        last->next = (struct IJSON_(_stream_node) *)
            malloc(sizeof(struct IJSON_(_stream_node)));
        last->next->prev = last;
        last->next->next = NULL;
        last = last->next;
        stream->last = last;

        last->data = (char *) malloc(sizeof(char) * nodelen);

        if (length < stream->node_length) {
            strncpy(last->data, data + pos, length);
            last->clength = length;
            stream->stream_length += length;
            length = 0;
        } else {
            strncpy(last->data, data + pos, nodelen);
            last->clength = nodelen;
            stream->stream_length += nodelen;
            length -= nodelen;
            pos += nodelen;
        }
    }

    return stream->stream_length;
}

char *IJSON_(_stream_substr)(struct IJSON_(_stream) *stream,
        int start, int end)
{
    if (start < 0) start = stream->stream_length + start + 1;
    if (end < 0) end = stream->stream_length + end + 1;

    size_t nodelen = stream->node_length;
    char *data = malloc(sizeof(char) * (end - start));

    size_t pos = 0;
    size_t count = 0;
    for (struct IJSON_(_stream_node) *node = stream->first;
            node && pos < end; node = node->next) {
        if (pos < start) {
            if (start - pos < nodelen) {
                pos = start;
                size_t i = pos % nodelen;
                size_t l = nodelen - i;
                strncpy(data, node->data + i, l);
                pos += l;
                count += l;
            } else {
                pos += nodelen;
            }
        } else if (end - pos < nodelen) {
            strncpy(data + count, node->data, end - pos);
            pos = end;
        } else {
            strncpy(data + count, node->data, nodelen);
            pos += nodelen;
            count += nodelen;
        }
    }

    return data;
}

void IJSON_(_stream_release)(struct IJSON_(_stream) *stream)
{
    struct IJSON_(_stream_node) *node, *next;
    node = stream->first;
    while (node) {
        next = node->next;
        free(node->data);
        free(node);
        node = next;
    }
}
void IJSON_(_stream_free)(struct IJSON_(_stream) *stream)
{ IJSON_(_stream_release)(stream); free(stream); }


static void _state_release(IJSON_(state) *state);


void IJSON_(doc_init)(IJSON_(document) *doc, size_t block_size)
{
    doc->root_state = NULL;
    IJSON_(_stream_init)(&doc->data, block_size);
}

void IJSON_(doc_data)(IJSON_(document) *doc, size_t length, const char *data)
{
    IJSON_(_stream_append)(&doc->data, length, data);
}

void IJSON_(doc_release)(IJSON_(document) *doc)
{
    IJSON_(_stream_release)(&doc->data);
    if (doc->root_state) {
        _state_release(doc->root_state);
        free(doc->root_state);
    }
}


static IJSON_(state) *_state_push(IJSON_(state) *parent, int replace)
{
    IJSON_(state) *state = (IJSON_(state) *) malloc(sizeof(IJSON_(state)));
    state->status = IJSON_OK;
    state->token = NULL;

    state->_info = parent->_info;
    if (replace) {
        _state_release(parent);
        free(parent);
    } else {
        state->_info.parent = parent;
    }

    return state;
}

static IJSON_(state) *_state_pop(IJSON_(state) *state)
{
    IJSON_(state) *next = state->_info.parent;
    _state_release(state);
    free(state);
    return next;
}

static void _state_release(IJSON_(state) *state)
{
    free(state->token);
}

IJSON_(state) *IJSON_(start)(IJSON_(document) *doc)
{
    doc->root_state = (IJSON_(state) *) malloc(sizeof(IJSON_(state)));

    IJSON_(state) *state = doc->root_state;
    state->status = IJSON_OK;
    state->token = NULL;

    state->_info.parent = NULL;
    state->_info.data_node = doc->data.first;
    state->_info.data_size = doc->data.node_length;

    state->_info.data_pos = 0;
    state->_info.line = 0;
    state->_info.col = 0;

    return IJSON_(step)(_state_push(state, 0));
}

static int _parse_peek(IJSON_(state) *state);
static int _parse_ch(IJSON_(state) *state);
static _Bool _parse_is_ws(int c);
static _Bool _parse_is_term(int c);
static void _parse_kw(IJSON_(state) *state, const char *rest);

IJSON_(state) *IJSON_(step)(IJSON_(state) *state)
{
    int c;
    do {
        c = _parse_ch(state);
    } while (_parse_is_ws(c));

    switch (c) {
    case -1:
        state = _state_push(state, 0);
        state->status = IJSON_EOF;
        return state;
    case 'n':
        state = _state_push(state, 1);
        state->token = (IJSON_(value) *) malloc(sizeof(IJSON_(any)));
        state->token->info.type = IJSON_VALUE_NULL;
        _parse_kw(state, "ull");
        return state;
    case 't':
        state = _state_push(state, 1);
        state->token = (IJSON_(value) *) malloc(sizeof(IJSON_(integer)));
        state->token->info.type = IJSON_VALUE_BOOLEAN;
        state->token->integer.data = 1;
        _parse_kw(state, "rue");
        return state;
    case 'f':
        state = _state_push(state, 1);
        state->token = (IJSON_(value) *) malloc(sizeof(IJSON_(integer)));
        state->token->info.type = IJSON_VALUE_BOOLEAN;
        state->token->integer.data = 0;
        _parse_kw(state, "alse");
        return state;
    default:
        state = _state_push(state, 0);
        state->status = IJSON_UNEXPECTED;
        return state;
    }
}

static int _parse_peek(IJSON_(state) *state)
{
    if (state->_info.data_pos >= state->_info.data_size
            || state->_info.data_pos >= state->_info.data_node->clength) {
        return -1;
    }

    return state->_info.data_node->data[state->_info.data_pos];
}

static int _parse_ch(IJSON_(state) *state)
{
    int c = _parse_peek(state);
    state->_info.data_pos += 1;
    if (c == '\n') {
        state->_info.line += 1;
        state->_info.col = 0;
    } else {
        state->_info.col += 1;
    }

    if (state->_info.data_pos >= state->_info.data_size
            && state->_info.data_node->next) {
        state->_info.data_node = state->_info.data_node->next;
        state->_info.data_pos = 0;
    }

    return c;
}

static _Bool _parse_is_ws(int c)
{
    return c == ' ' || c == '\t'
        || c == '\n' || c == '\r';
}

static _Bool _parse_is_term(int c)
{
    return c == -1 || _parse_is_ws(c)
        || c == ':' || c == ','
        || c == ']' || c == '}';
}

static void _parse_kw(IJSON_(state) *state, const char *rest)
{
    char c;
    for (int i = 0; c = rest[i]; i += 1) {
        if (_parse_ch(state) != c) {
            state->status = IJSON_UNEXPECTED;
            return;
        }
    }

    if (_parse_is_term(_parse_peek(state))) {
        state->status = IJSON_OK;
    } else {
        _parse_ch(state);
        state->status = IJSON_UNEXPECTED;
    }
}
