
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
#include <pthread.h>
#include "ahocorasick.h"

void callback_match_pos(VALUE rb_result_container, void *arg, struct aho_match_t* m)
{
    
    unsigned int i = m->pos, idx = 0;

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
  int state;
  VALUE result = rb_hash_new();
  struct ahocorasick aho;
  aho_init(&aho);
  char *target = StringValuePtr(body);
  long size =  RARRAY_LEN(keys);
  
  for(long idx = 0; idx < size; idx++) {
    VALUE entry = rb_ary_entry(keys, idx);
    char *key_text;

    if (!RB_TYPE_P(entry, T_STRING)) {
      entry = rb_funcall(entry, rb_intern("to_s"), 0);
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
  int state;

  struct ahocorasick aho;

  char *target = StringValuePtr(body);
  VALUE keys = rb_funcall(replace, rb_intern("keys"), 0);
  VALUE replace_values = rb_funcall(replace, rb_intern("values"), 0);
  long size =  RARRAY_LEN(keys);

  long value_sizes[size];
  char *values[size];
  VALUE ruby_val[size];
  
  aho_init(&aho);

  for(long idx = 0; idx < size; idx++) {
    VALUE entry = rb_ary_entry(keys, idx);
    VALUE value = rb_ary_entry(replace_values, idx);

    char *key_text;

    if (!RB_TYPE_P(entry, T_STRING)) {
      entry = rb_funcall(entry, rb_intern("to_s"), 0);
    }

    if (RB_TYPE_P(value, T_STRING)) {
      values[idx] = StringValuePtr(value);
      value_sizes[idx] = RSTRING_LEN(value);
    } else {
      values[idx] = NULL;
      ruby_val[idx] = value;
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
  int state;
  VALUE mod = rb_eval_string_protect("MultiStringReplace", &state);

  if (state)
  {
    /* handle exception */
  } else {
  rb_define_singleton_method(mod, "match", multi_string_match, 2);
  rb_define_singleton_method(mod, "replace", multi_string_replace, 2);
  }

}

