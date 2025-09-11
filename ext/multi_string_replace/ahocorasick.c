
// MIT License

// Copyright (c) 2017 morenice

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

#include <limits.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "ahocorasick.h"
#include "aho_trie.h"

extern void aho_init(struct ahocorasick * restrict aho)
{
    memset(aho, 0x00, sizeof(struct ahocorasick));
}

void aho_destroy(struct ahocorasick * restrict aho)
{
    aho_clear_match_text(aho);
    aho_clear_trie(aho);
}

int aho_add_match_text(struct ahocorasick * restrict aho, const char* text, unsigned int len)
{
    struct aho_text_t* a_text = NULL;

    if (aho->accumulate_text_id == AHO_MAX_TEXT_ID)
    {
        return -1;
    }

    a_text = (struct aho_text_t*) malloc(sizeof(struct aho_text_t));
    if (!a_text)
        goto lack_free_mem;

    a_text->text = (char*) malloc(sizeof(char)*(len + 1));

    if (!a_text->text)
        goto lack_free_mem;

    a_text->id = aho->accumulate_text_id++;

    // Copy exactly len bytes and add terminator once
    memcpy(a_text->text, text, len);
    a_text->text[len] = '\0';

    a_text->len = len;
    a_text->prev = NULL;
    a_text->next = NULL;

    if (aho->text_list_head == NULL)
    {
        aho->text_list_head = a_text;
        aho->text_list_tail = a_text;
        aho->text_list_len++;
        return a_text->id;
    }

    aho->text_list_tail->next = a_text;
    a_text->prev = aho->text_list_tail;
    aho->text_list_tail = a_text;
    aho->text_list_len++;
    return a_text->id;

lack_free_mem:
    
    return -1;
}

bool aho_del_match_text(struct ahocorasick * restrict aho, const int id)
{
    struct aho_text_t* iter = NULL;
    for (iter = aho->text_list_head; iter != NULL; iter = iter->next)
    {
        /*if (iter->id > id)
        {
            return false;
        }
        */

        if (iter->id == id)
        {
            if (iter == aho->text_list_head)
            {
                aho->text_list_head = iter->next;
                free(iter->text);
            }
            else if (iter == aho->text_list_tail)
            {
                aho->text_list_tail = iter->prev;
                free(iter->text);
            }
            else
            {
                iter->prev->next = iter->next;
                iter->next->prev = iter->prev;
                free(iter->text);
            }
            free(iter);
            aho->text_list_len--;
            return true;
        }
    }
    return false;
}

void aho_clear_match_text(struct ahocorasick * restrict aho)
{
    struct aho_text_t* iter = aho->text_list_head;
    while (iter) {
        struct aho_text_t* nxt = iter->next;
        free(iter->text);
        free(iter);
        iter = nxt;
    }
    // reset
    aho->accumulate_text_id = 0;
    aho->text_list_head = NULL;
    aho->text_list_tail = NULL;
    aho->text_list_len = 0;
}


void aho_create_trie(struct ahocorasick * restrict aho)
{
    struct aho_text_t* iter = NULL;
    aho_init_trie(&(aho->trie));

    for (iter = aho->text_list_head; iter != NULL; iter = iter->next)
    {

        aho_add_trie_node(&(aho->trie), iter);

    }

    aho_connect_link(&(aho->trie));

    /* debugging */
    //aho_print_trie(&(aho->trie));
}

void aho_clear_trie(struct ahocorasick * restrict aho)
{
    aho_destroy_trie(&aho->trie);
}

unsigned int aho_findtext(struct ahocorasick * restrict aho, const char* data, unsigned long long data_len)
{
    unsigned long long i = 0;
    int match_count = 0;
    struct aho_trie_node* travasal_node = NULL;

    travasal_node = &(aho->trie.root);

    for (i = 0; i < data_len; i++)
    {
        struct aho_match_t match;
        struct aho_text_t* result;

        // ASCII fast-path: when at root with no child for byte, skip
        if (travasal_node->parent == NULL && travasal_node->child_list[(unsigned char)data[i]] == NULL) {
            continue;
        }
        result = aho_find_trie_node(&travasal_node, data[i]);
        if (result == NULL)
        {
            continue;
        }

        match.id = result->id;
        match.len = result->len;

    match.pos = i - result->len + 1;

        match_count++;
        if (aho->callback_match)
        {
            aho->callback_match(aho->rb_result_container, aho->callback_arg, &match);
        }
    }

    return match_count;
}

VALUE aho_replace_text(struct ahocorasick * restrict aho, const char* data,
    unsigned long long data_len, char *values[], long value_sizes[], VALUE ruby_values[])
{
    unsigned long long i = 0;
    struct aho_trie_node* travasal_node = NULL;

    travasal_node = &(aho->trie.root);
    // Defer allocation until first match; handle no-match fast path
    VALUE main_result = Qnil;
    unsigned long long last_concat_pos = 0;

    for (i = 0; i < data_len; i++)
    {
        struct aho_text_t* result;

        result = aho_find_trie_node(&travasal_node, data[i]);
        if (result == NULL)
        {
            continue;
        }

    const int rlen = result->len;
    unsigned long long pos = i - rlen + 1;

        // On first match, allocate result and copy prefix if any
        if (NIL_P(main_result)) {
            main_result = rb_str_buf_new((long)data_len);
            if (pos > 0) rb_str_cat(main_result, &data[0], pos);
        } else if (pos > last_concat_pos) {
            rb_str_cat(main_result, &data[last_concat_pos], pos - last_concat_pos);
        }
        
        // concatenate replace
        const int rid = result->id;
        if (values[rid] == NULL) {
            // NULL value indicates either: (1) no replacement supplied, or (2) a proc to compute it
            if (!NIL_P(ruby_values[rid])) {
                VALUE proc_result = rb_funcall(ruby_values[rid], rb_intern("call"), 2, LONG2NUM((long)pos), LONG2NUM((long)(pos + rlen)));
                if (RB_TYPE_P(proc_result, T_NIL)) {
                    rb_str_cat(main_result, &data[pos], rlen);
                    last_concat_pos = i + 1;
                    continue;
                } else if (RB_TYPE_P(proc_result, T_STRING)) {
                    rb_str_cat(main_result, StringValuePtr(proc_result), RSTRING_LEN(proc_result));
                    last_concat_pos = i + 1;
                    continue;
                } else {
                    VALUE string_result = rb_funcall(proc_result, rb_intern("to_s"), 0);
                    rb_str_cat(main_result, StringValuePtr(string_result), RSTRING_LEN(string_result));
                    last_concat_pos = i + 1;
                    continue;
                }
            } else {
                // no replacement provided; keep original slice
                rb_str_cat(main_result, &data[pos], rlen);
                last_concat_pos = i + 1;
                continue;
            }
        }

        rb_str_cat(main_result, values[rid], value_sizes[rid]); 
        last_concat_pos = i + 1;
    }

    if (NIL_P(main_result)) {
        // No matches; return a copy of input (preserves previous API behavior of returning a new String)
        return rb_str_new(data, (long)data_len);
    } else {
        if (last_concat_pos < data_len) {
            rb_str_cat(main_result, &data[last_concat_pos], (long)(data_len - last_concat_pos));
        }
        return main_result;
    }
}

inline void aho_register_match_callback(VALUE rb_result_container, struct ahocorasick * restrict aho,
        void (*callback_match)(VALUE rb_result_container, void* arg, struct aho_match_t*),
        void *arg)
{
    aho->callback_arg = arg;
    aho->callback_match = callback_match;
    aho->rb_result_container = rb_result_container;
}

void aho_print_match_text(struct ahocorasick * restrict aho)
{
    struct aho_text_t* iter = NULL;
    for (iter = aho->text_list_head; iter != NULL; iter = iter->next)
    {
        printf("id:%d text:%s len:%d this:%p prev:%p next:%p\n",
                iter->id, iter->text, iter->len, iter, iter->prev, iter->next);
    }
}
