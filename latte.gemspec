# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "latte/version"

Gem::Specification.new do |s|
  s.name        = "latte"
  s.version     = Latte::VERSION
  s.authors     = ["Craig R Webster"]
  s.email       = ["craig@barkingiguana.com"]
  s.homepage    = ""
  s.summary     = %q{A DNS framework with configurable query resolver}
  s.description = %q{Talks DNS and passes queries back to a query resolver build by you that just talks Ruby}

  s.rubyforge_project = "latte"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "pethau", ">= 0.0.2"
  s.add_runtime_dependency "net-dns"
  s.add_runtime_dependency "null_logger"
  s.add_runtime_dependency "bindata"
end
