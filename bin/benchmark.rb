require "bundler/setup"
require 'multi_string_replace'
require 'benchmark'
require 'pry-byebug'

body = File.read(File.join('spec', 'fixtures', 'test.txt'))

replace = {
  'Lorem' => 'XXXX',
  'ipsum' => 'yyyyy',
  'sapien' => 'zzzzzz',
  'sed' => 'pppppppp',
  'Fusce' => 'wwwwwwww',
  'non' => 'NON',
  'sit' => 'SIT',
  'laoreet' => 'lllll',
  'Cras' => 'uuuuuuuu',
  'nunc' => 'eeeeeee',
  'cursus' => 'dfsdfsf'
}

File.write('replaced.txt', body.gsub(/(#{replace.keys.join('|')})/, replace))
puts Benchmark.measure { 
  1000.times { body.gsub(/(#{replace.keys.join('|')})/,  replace) }
}

sub = MultiStringReplace::Substitution.new(replace.keys).for(body)

puts Benchmark.measure { 
  1000.times { sub.process(replace) }
}

sub = MultiStringReplace::Substitution.new(replace.keys)

puts Benchmark.measure { 
  1000.times { sub.match(body) }
}