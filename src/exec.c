#include <mruby.h>
#include <mruby/error.h>
#include <mruby/string.h>

#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

static void myfree(char**, mrb_int);
static mrb_value myexecvp(mrb_state*, mrb_value);
static mrb_value myexit(mrb_state*, mrb_value);
static mrb_value mywarn(mrb_state*, mrb_value);

void
mrb_mruby_pledge_gem_init(mrb_state *mrb)
{
  mrb_define_method(mrb, mrb->kernel_module, "execvp", myexecvp, MRB_ARGS_REST());
  mrb_define_method(mrb, mrb->kernel_module, "exit", myexit, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, mrb->kernel_module, "warn", mywarn, MRB_ARGS_REQ(1));
}

void
mrb_mruby_pledge_gem_final(mrb_state *mrb)
{
  (void) mrb;
}

static mrb_value
myexecvp(mrb_state *mrb, mrb_value self)
{
  char **cargs, *file;
  mrb_value *args;
  mrb_int count;

  mrb_get_args(mrb, "*", &args, &count);
  if(count == 0) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "No arguments given");
  } else {
    cargs = calloc(count + 1, sizeof(char*));
    if (cargs == NULL) {
      mrb_sys_fail(mrb, "calloc");
    }
  }

  for(mrb_int i = 0; i < count; i++) {
    if(!mrb_string_p(args[i])) {
      myfree(cargs, count);
      mrb_raise(mrb, E_TYPE_ERROR, "expected a string");
    }
    if(i == 0) {
      file = strdup(RSTRING_PTR(args[i]));
    } else {
      cargs[i-1] = strdup(RSTRING_PTR(args[i]));
    }
  }

  if(count == 1) {
    cargs[0] = "";
    cargs[1] = NULL;
  }

  if (execvp(file, cargs) == -1) {
    myfree(cargs, count);
    mrb_sys_fail(mrb, "execvp");
  }

  return mrb_nil_value();
}

static mrb_value
myexit(mrb_state *mrb, mrb_value self) {
  mrb_int exitcode;
  mrb_get_args(mrb, "i", &exitcode);
  exit(exitcode);
}

static mrb_value
mywarn(mrb_state *mrb, mrb_value self) {
  const char *warning;
  mrb_get_args(mrb, "z", &warning);
  fprintf(stderr, "%s\n", warning);
  return mrb_nil_value();
}

static void
myfree(char **ary, mrb_int len)
{
  if(ary == NULL) {
    return;
  }
  for(mrb_int i = 0; i < len; i++) {
    if(ary[i] != NULL)
      free(ary[i]);
  }
  free(ary);
}
