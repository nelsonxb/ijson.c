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
        size_t start, size_t end)
{
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


void IJSON_(doc_init)(IJSON_(document) *doc, size_t block_size)
{
    // TODO
}

void IJSON_(doc_data)(IJSON_(document) *doc, size_t length, const char *data)
{
    // TODO
}

void IJSON_(doc_release)(IJSON_(document) *doc)
{
    // TODO
}
