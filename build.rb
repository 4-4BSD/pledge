MRuby::Build.new('pledge') do |conf|
  conf.toolchain :clang

  conf.cc.defines << 'MRB_NO_FLOAT'
  conf.cc.defines << 'MRB_CONSTRAINED_BASELINE_PROFILE'
  conf.cc.defines << 'MRB_NO_METHOD_CACHE'
  conf.cc.defines << 'MRB_GC_FIXED_ARENA'
  conf.cc.defines << 'MRB_INT32'

  conf.cc.defines << 'MRB_STR_LENGTH_MAX=4096'
  conf.cc.defines << 'MRB_ARY_LENGTH_MAX=256'
  conf.cc.defines << 'MRB_FUNCALL_ARGC_MAX=8'

  conf.gem core: 'mruby-compiler'
  conf.gem core: 'mruby-bin-mrbc'
  conf.gem core: 'mruby-bin-config'
  conf.gem '.'
end