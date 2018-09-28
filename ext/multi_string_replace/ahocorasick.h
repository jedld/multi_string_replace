

// MIT License

// Copyright (c) 2017 morenice

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

#pragma once

#include <stdbool.h>
#include "aho_trie.h"
#include "aho_text.h"
#include "ruby.h"

struct aho_match_t
{
    int id;
    unsigned long long pos;
    int len;
};

struct ahocorasick
{
#define AHO_MAX_TEXT_ID INT_MAX
    int accumulate_text_id;
    struct aho_text_t* text_list_head;
    struct aho_text_t* text_list_tail;
    int text_list_len;

    struct aho_trie trie;

    void (*callback_match)(VALUE rb_result_container, void* arg, struct aho_match_t*);
    void* callback_arg;
    VALUE rb_result_container;
};

void aho_init(struct ahocorasick * restrict aho);
void aho_destroy(struct ahocorasick * restrict aho);

int aho_add_match_text(struct ahocorasick * restrict aho, const char* text, unsigned int len);
bool aho_del_match_text(struct ahocorasick * restrict aho, const int id);
void aho_clear_match_text(struct ahocorasick * restrict aho);

void aho_create_trie(struct ahocorasick * restrict aho);
void aho_clear_trie(struct ahocorasick * restrict aho);

unsigned int aho_findtext(struct ahocorasick * restrict aho, const char* data, unsigned long long data_len);
VALUE aho_replace_text(struct ahocorasick * restrict aho, const char* data,
    unsigned long long data_len, char *values[], long value_sizes[], VALUE ruby_values[]);

void aho_register_match_callback(VALUE rb_result_container, struct ahocorasick * restrict aho,
        void (*callback_match)(VALUE rb_result_container, void* arg, struct aho_match_t*),
        void *arg);

/* for debug */
void aho_print_match_text(struct ahocorasick * restrict aho);
