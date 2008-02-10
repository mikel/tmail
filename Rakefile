require 'rubygems'
require 'rake'
require 'rake/testtask'

# Run the unit tests
# QUESTION: Is this suppose to be a live test?
Rake::TestTask.new { |t|
  t.libs << "test"
  #t.libs << "lib"
  #t.libs << "ext/tmailscanner"
  t.pattern = 'test/test_*.rb'
  t.verbose = true
  t.warning = false
}

desc "Generate rdocs"
task :rdoc do
  sh "script/rdoc"
end

desc "Compile extensions"
task :make do
  sh "script/make"
end


