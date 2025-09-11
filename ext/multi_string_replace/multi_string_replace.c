
// MIT License

// Copyright (c) 2018 Joseph Dayo

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

#include "ruby.h"
#include "extconf.h"
#include <stdio.h>
#include <string.h>
#include "ahocorasick.h"

// Cached Ruby IDs for method lookups
static ID id_keys;
static ID id_values;
static ID id_to_s;
static ID id_call;

// Forward declaration used by Automaton methods
void callback_match_pos(VALUE rb_result_container, void *arg, struct aho_match_t* m);

// Automaton wrapper for reuse across calls
typedef struct {
  struct ahocorasick aho;
  VALUE keys_ary; // Ruby array of keys in insertion order (kept for GC safety and lookups)
  int built;
} automaton_t;

static void automaton_free(void *ptr) {
  if (!ptr) return;
  automaton_t *au = (automaton_t*)ptr;
  aho_destroy(&au->aho);
  xfree(au);
}

static size_t automaton_size(const void *ptr) {
  return ptr ? sizeof(automaton_t) : 0;
}

static void automaton_mark(void *ptr) {
  if (!ptr) return;
  automaton_t *au = (automaton_t*)ptr;
  if (!NIL_P(au->keys_ary)) rb_gc_mark(au->keys_ary);
}

static const rb_data_type_t automaton_type = {
  "MultiStringReplace::Automaton",
  { automaton_mark, automaton_free, automaton_size, },
  0, 0, RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE automaton_alloc(VALUE klass) {
  automaton_t *au;
  VALUE obj = TypedData_Make_Struct(klass, automaton_t, &automaton_type, au);
  memset(au, 0, sizeof(*au));
  aho_init(&au->aho);
  au->built = 0;
  au->keys_ary = Qnil;
  return obj;
}

static VALUE automaton_initialize(VALUE self, VALUE keys) {
  automaton_t *au;
  TypedData_Get_Struct(self, automaton_t, &automaton_type, au);
  Check_Type(keys, T_ARRAY);
  long size = RARRAY_LEN(keys);
  au->keys_ary = rb_ary_new_capa(size);

  for (long idx = 0; idx < size; idx++) {
    VALUE entry = rb_ary_entry(keys, idx);
    if (!RB_TYPE_P(entry, T_STRING)) {
      entry = rb_funcall(entry, id_to_s, 0);
    }
    rb_ary_push(au->keys_ary, entry); // keep a reference
    aho_add_match_text(&au->aho, StringValuePtr(entry), RSTRING_LEN(entry));
  }
  aho_create_trie(&au->aho);
  au->built = 1;
  return self;
}

static VALUE automaton_match(VALUE self, VALUE body) {
  automaton_t *au;
  TypedData_Get_Struct(self, automaton_t, &automaton_type, au);
  if (!au->built) return rb_hash_new();
  VALUE result = rb_hash_new();
  char *target = StringValuePtr(body);
  aho_register_match_callback(result, &au->aho, callback_match_pos, (void*)target);
  aho_findtext(&au->aho, target, RSTRING_LEN(body));
  return result;
}

static VALUE automaton_replace(VALUE self, VALUE body, VALUE replace) {
  automaton_t *au;
  TypedData_Get_Struct(self, automaton_t, &automaton_type, au);
  if (!au->built) return body;
  Check_Type(replace, T_HASH);

  long size = RARRAY_LEN(au->keys_ary);
  char **values = ALLOCA_N(char*, size);
  long *value_sizes = ALLOCA_N(long, size);
  VALUE *ruby_val = ALLOCA_N(VALUE, size);
  for (long i = 0; i < size; i++) { values[i] = NULL; value_sizes[i] = 0; ruby_val[i] = Qnil; }

  // Build arrays aligned with internal ids: id == index of key in keys_ary
  for (long idx = 0; idx < size; idx++) {
    VALUE key = rb_ary_entry(au->keys_ary, idx);
    VALUE value = rb_hash_aref(replace, key);
    if (NIL_P(value)) {
      // no replacement provided => keep original text when encountered
      values[idx] = NULL; // signals "copy original"
      ruby_val[idx] = Qnil;
      continue;
    }
    if (RB_TYPE_P(value, T_STRING)) {
      values[idx] = StringValuePtr(value);
      value_sizes[idx] = RSTRING_LEN(value);
      ruby_val[idx] = value; // GC keep
    } else if (rb_respond_to(value, id_call)) {
      values[idx] = NULL;
      ruby_val[idx] = value;
    } else {
      VALUE s = rb_funcall(value, id_to_s, 0);
      values[idx] = StringValuePtr(s);
      value_sizes[idx] = RSTRING_LEN(s);
      ruby_val[idx] = s;
    }
  }

  char *target = StringValuePtr(body);
  return aho_replace_text(&au->aho, target, RSTRING_LEN(body), values, value_sizes, ruby_val);
}

void callback_match_pos(VALUE rb_result_container, void *arg, struct aho_match_t* m)
{
  // Append match position to array keyed by token id
    VALUE key = LONG2NUM(m->id);
    VALUE hash_value = rb_hash_aref(rb_result_container, key);

    if (NIL_P(hash_value)) {
      hash_value = rb_ary_new();
      rb_hash_aset(rb_result_container, key, hash_value);
    }
    rb_ary_push(hash_value, LONG2NUM(m->pos)) ;
}

VALUE multi_string_match(VALUE self, VALUE body, VALUE keys)
{
  Check_Type(keys, T_ARRAY);
  VALUE result = rb_hash_new();
  struct ahocorasick aho;
  aho_init(&aho);
  char *target = StringValuePtr(body);
  long size =  RARRAY_LEN(keys);
  
  for(long idx = 0; idx < size; idx++) {
    VALUE entry = rb_ary_entry(keys, idx);
    if (!RB_TYPE_P(entry, T_STRING)) {
  entry = rb_funcall(entry, id_to_s, 0);
    }

    aho_add_match_text(&aho, StringValuePtr(entry), RSTRING_LEN(entry));
  }

  aho_create_trie(&aho);
  aho_register_match_callback(result, &aho, callback_match_pos, (void*)target);

  aho_findtext(&aho, target, RSTRING_LEN(body));
  aho_destroy(&aho);
  return result;
}

VALUE multi_string_replace(VALUE self, VALUE body, VALUE replace)
{
  Check_Type(replace, T_HASH);
  struct ahocorasick aho;

  char *target = StringValuePtr(body);
  VALUE keys = rb_funcall(replace, id_keys, 0);
  VALUE replace_values = rb_funcall(replace, id_values, 0);
  long size =  RARRAY_LEN(keys);

  if (size == 0) {
    // Nothing to replace; return a copy of input (preserves API semantics)
    return rb_str_dup(body);
  }

  long value_sizes[size];
  char *values[size];
  VALUE ruby_val[size];
  for (long i = 0; i < size; i++) ruby_val[i] = Qnil; // GC guard and init
  
  aho_init(&aho);

  for(long idx = 0; idx < size; idx++) {
    VALUE entry = rb_ary_entry(keys, idx);
    VALUE value = rb_ary_entry(replace_values, idx);

    if (!RB_TYPE_P(entry, T_STRING)) {
      entry = rb_funcall(entry, id_to_s, 0);
    }

    if (RB_TYPE_P(value, T_STRING)) {
      values[idx] = StringValuePtr(value);
      value_sizes[idx] = RSTRING_LEN(value);
      ruby_val[idx] = value; // keep VALUE alive
    } else {
      if (rb_respond_to(value, id_call)) {
        values[idx] = NULL;
        ruby_val[idx] = value;
      } else {
        VALUE value_as_string = rb_funcall(value, id_to_s, 0);
        values[idx] = StringValuePtr(value_as_string);
        value_sizes[idx] = RSTRING_LEN(value_as_string);
        ruby_val[idx] = value_as_string; // keep VALUE alive
      }
    }

   aho_add_match_text(&aho, StringValuePtr(entry), RSTRING_LEN(entry));
  }
  aho_create_trie(&aho);
  VALUE result = aho_replace_text(&aho, target, RSTRING_LEN(body), values, value_sizes, ruby_val);
  aho_destroy(&aho);
  return result;
}

void Init_multi_string_replace()
{
  // Cache frequently used IDs
  id_keys = rb_intern("keys");
  id_values = rb_intern("values");
  id_to_s = rb_intern("to_s");
  id_call = rb_intern("call");
  // Define or fetch the module without evaluating Ruby code
  VALUE mod = rb_define_module("MultiStringReplace");
  rb_define_singleton_method(mod, "match", multi_string_match, 2);
  rb_define_singleton_method(mod, "replace", multi_string_replace, 2);

  // Define Automaton class under module
  VALUE cAutomaton = rb_define_class_under(mod, "Automaton", rb_cObject);
  rb_define_alloc_func(cAutomaton, automaton_alloc);
  rb_define_method(cAutomaton, "initialize", automaton_initialize, 1);
  rb_define_method(cAutomaton, "match", automaton_match, 1);
  rb_define_method(cAutomaton, "replace", automaton_replace, 2);
  // Convenience builder: Automaton.build(keys)
  rb_define_singleton_method(cAutomaton, "build", RUBY_METHOD_FUNC(rb_class_new_instance), -1);

}

