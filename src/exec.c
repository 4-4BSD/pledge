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
  char **argv, *file;
  mrb_value *args;
  mrb_int count;

  mrb_get_args(mrb, "*", &args, &count);
  if(count == 0) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "No arguments given");
  }
  argv = calloc(count + 1, sizeof(char*));
  if (argv == NULL) {
    mrb_sys_fail(mrb, "calloc");
  }
  for(mrb_int i = 0; i < count; i++) {
    if(!mrb_string_p(args[i])) {
      myfree(argv, count);
      mrb_raise(mrb, E_TYPE_ERROR, "expected a string");
    }
    char *str = RSTRING_PTR(args[i]);
    argv[i] = strdup(str);
  }

  file = argv[0];
  if (execvp(file, argv) == -1) {
    myfree(argv, count);
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
  mrb_value *args;
  mrb_int count;

  mrb_get_args(mrb, "*", &args, &count);
  if (count == 0) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "Expected at least one argument, got none");
  }
  for (mrb_int i = 0; i < count; i++) {
    fprintf(stderr, "%s", RSTRING_PTR(args[i]));
  }
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
