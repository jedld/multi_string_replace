#include "ruby.h"
#include "extconf.h"
#include <stdio.h>
#include <string.h>
#include <pthread.h>
#include "ahocorasick.h"

void callback_match_total(void *arg, struct aho_match_t* m)
{
    long long int* match_total = (long long int*)arg;
    (*match_total)++;
}

void callback_match_pos(void *arg, struct aho_match_t* m)
{
    char* text = (char*)arg;

    printf("match text:");
    for(unsigned int i = m->pos; i < (m->pos+m->len); i++)
    {
        printf("%c", text[i]);
    }

    printf(" (match id: %d position: %llu length: %d)\n", m->id, m->pos, m->len);
}

VALUE multi_string_match(VALUE body, VALUE keys)
{
  int state;
  rb_eval_string("puts \"start\" ");
  // if ( (RB_TYPE_P(body, T_STRING) == 1) && (RB_TYPE_P(keys, T_ARRAY) == 1)) {
    struct ahocorasick aho;
    aho_init(&aho);
    char *target = StringValueCStr(body);
    int size = FIX2LONG(rb_ary_size(keys));
    rb_eval_string(sprintf("puts \"size %d\"", size));
    for(long idx = 0; idx < size; idx++) {
      VALUE entry = rb_ary_entry(keys, idx);
      char *key_text = StringValueCStr(entry);
      rb_eval_string(sprintf("puts \"%s\"", key_text));
      aho_add_match_text(&aho,  key_text, strlen(key_text));
    }
    aho_create_trie(&aho);
    long count = aho_findtext(&aho, target, strlen(target));
    aho_destroy(&aho);
    return LONG2FIX(count);
  // }
  return LONG2FIX(0);;
}

void Init_multi_string_replace()
{
  VALUE mod = rb_define_module("MultiStringReplaceExt");
  rb_define_singleton_method(mod, "match", multi_string_match, 2);
}

