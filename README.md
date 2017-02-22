# ijson.c - Iterative/incremental JSON parser #

ijson is a small, dead simple JSON parser. Its API is much like an iterator
(or generator). It doesn't have any built-in representation, and it avoids
using callbacks (because seriously - screw callbacks in C).


## Usage ##

Copy `ijson.c` and `ijson.h` to somewhere in your projects' source.

> **NOTE:** This API is not yet implemented, and subject to change.

```c
// Take a JSON document like
/* { "name": "World", "greeting": "Hello" } */

struct {
    char *name;
    char *greeting;
} message = { NULL, NULL };

ijson_document doc;
ijson_doc_init(&doc);
ijson_state *state = ijson_start(&doc);
if (state->token->info.type != IJSON_VALUE_OBJECT) {
    // some error code
}

for (; state; state = ijson_step(state)) {
    if (state->status) {
        // some error code
    }

    if (state->token->info.type != IJSON_PAIR) {
        // some error code
    }

    ijson_pair *pair = &state->token->pair;
    if (pair->value->info.type != IJSON_VALUE_STRING) {
        // some error code
    }
    ijson_string *s = &pair->value->string;
    if (strcmp(pair->key.data, "name") == 0) {
        message.name = s->data;
    } else if (strcmp(pair->key.data, "greeting") == 0) {
        message.greeting = s->data;
    }
}

printf("%s, %s!\n", message.greeting, message.name);
```
