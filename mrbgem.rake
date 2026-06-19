MRuby::Gem::Specification.new("mruby-pledge") do |spec|
  spec.license = '0BSD'
  spec.author  = 'robert <robert@4.4bsd.dev>'
  spec.summary = 'Launch programs in a sandbox'
  spec.add_dependency "mruby-hardened-pledge", github: "0x1eef/mruby-hardened-pledge"
end