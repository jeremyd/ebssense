Gem::Specification.new do |s|
  s.name = "ebssense"
  s.version = "0.0.1"
  s.summary = "Disk management tool for Ec2 EBS"
  s.authors = [ "Jeremy Deininger" ]
  s.email = [ "jeremydeininger@gmail.com" ]
  s.executables = ["ebssense"]
  s.bindir = "bin"
  s.files = Dir.glob("lib/**/*.rb") + \
    Dir.glob("spec/**/*.rb")
  s.add_dependency("aws-sdk", ">=1.7.1")
  s.add_dependency("trollop", ">=2.0")
  s.add_dependency("data_mapper", ">=0")
  s.add_dependency("dm-sqlite-adapter", ">=0")
  s.add_dependency('ruport', ">=0")
  s.add_dependency("pry")
  s.add_dependency("rspec")
end
