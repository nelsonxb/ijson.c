
#ifndef IJSON_H
#define IJSON_H
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


/*** CONFIGURATION ***/

/* Change `ijson_` to something else if you'd like to use a different prefix */
#define IJSON_(name) ijson_ ## name


/*** DEFINES ***/

#ifdef __cplusplus
extern "C" {
#endif


struct IJSON_(_stream_node) {
    size_t clength;
    char *data;
    struct IJSON_(_stream_node) *prev;
    struct IJSON_(_stream_node) *next;
};

struct IJSON_(_stream) {
    size_t stream_length;
    size_t node_length;
    struct IJSON_(_stream_node) *first;
    struct IJSON_(_stream_node) *last;
};

void IJSON_(_stream_init)(struct IJSON_(_stream) *stream, size_t node_length);

struct IJSON_(_stream) *IJSON_(_stream_new)(size_t node_length);

void IJSON_(_stream_find)(struct IJSON_(_stream) *stream, size_t idx,
        struct IJSON_(_stream_node) **out_node, size_t *out_idx);

int IJSON_(_stream_append)(struct IJSON_(_stream) *stream,
        size_t length, const char const *data);

char *IJSON_(_stream_substr)(struct IJSON_(_stream) *stream,
        int start, int end);

void IJSON_(_stream_release)(struct IJSON_(_stream) *stream);
void IJSON_(_stream_free)(struct IJSON_(_stream) *stream);

enum IJSON_(type) {
    IJSON_VALUE_NULL,
    IJSON_VALUE_BOOLEAN,
    IJSON_VALUE_INTEGER,
    IJSON_VALUE_DOUBLE,
    IJSON_VALUE_STRING,
    IJSON_COMPLEX_ARRAY,
    IJSON_COMPLEX_OBJECT,
    IJSON_PAIR,
};

union IJSON_(value);

struct IJSON_(value_info) {
    enum IJSON_(type) type;
};

typedef struct IJSON_(value_info) IJSON_(any);

typedef struct IJSON_(integer) {
    struct IJSON_(value_info) info;
    int data;
} IJSON_(integer);

typedef struct IJSON_(number) {
    struct IJSON_(value_info) info;
    double data;
} IJSON_(number);

typedef struct IJSON_(string) {
    struct IJSON_(value_info) info;
    size_t length;
    char *data;
} IJSON_(string);

typedef struct IJSON_(pair) {
    struct IJSON_(value_info) info;
    IJSON_(string) key;
    union IJSON_(value) *value;
} IJSON_(pair);

typedef union IJSON_(value) {
    struct IJSON_(value_info) info;
    IJSON_(integer) integer;
    IJSON_(number) number;
    IJSON_(string) string;
    IJSON_(pair) pair;
} IJSON_(value);


enum IJSON_(status) {
    IJSON_OK,
    IJSON_ERROR,
    IJSON_EOF,
    IJSON_UNEXPECTED
};

typedef struct IJSON_(state) {
    enum IJSON_(status) status;
    IJSON_(value) *token;

    struct {
        struct IJSON_(state) *parent;
        struct IJSON_(_stream_node) *data_node;
        size_t data_size, data_pos;
        int line, col;
    } _info;
} IJSON_(state);


typedef struct IJSON_(document) {
    struct IJSON_(_stream) data;
    IJSON_(state) *root_state;
} IJSON_(document);


void IJSON_(doc_init)(IJSON_(document) *doc, size_t block_size);
void IJSON_(doc_data)(IJSON_(document) *doc, size_t length, const char *data);
void IJSON_(doc_release)(IJSON_(document) *doc);

IJSON_(state) *IJSON_(start)(IJSON_(document) *doc);
IJSON_(state) *IJSON_(step)(IJSON_(state) *state);

#ifdef __cplusplus
}   /* end extern "C" */
#endif

/* end defined(IJSON_H) */
#endif
