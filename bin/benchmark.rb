require "bundler/setup"
require 'multi_string_replace'
require 'benchmark'
require 'optparse'

class String
  def mgsub(key_value_pairs=[].freeze)
    regexp_fragments = key_value_pairs.collect { |k,v| k }
    gsub( 
Regexp.union(*regexp_fragments)) do |match|
      key_value_pairs.detect{|k,v| k =~ match}[1]
    end
  end
end

options = { file: File.join('spec', 'fixtures', 'test.txt'), iters: 100, use_automaton: false }
OptionParser.new do |opts|
  opts.on('-f', '--file PATH', 'Input file path') { |v| options[:file] = v }
  opts.on('-n', '--iters N', Integer, 'Iterations') { |v| options[:iters] = v }
  opts.on('-A', '--automaton', 'Use Automaton for Msr run') { options[:use_automaton] = true }
end.parse!(ARGV)

body = File.read(options[:file])

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
  'cursus' => '乧乨乩乪乫乬乭乮乯买乱乲乳乴乵乶乷乸乹乺乻乼乽乾乿',
  'Vivamus' => '㐀㐁㐂㐃㐄㐅㐆㐇㐈㐉㐊㐋'
}

File.write('replaced.txt', body.gsub(/(#{replace.keys.join('|')})/, replace))
File.write('replaced2.txt', MultiStringReplace.replace(body, replace))

Benchmark.bmbm do |x|
  x.report "multi gsub" do options[:iters].times { body.mgsub(replace.map { |k, v| [/#{k}/, v] } ) } end
  if options[:use_automaton]
    ac = MultiStringReplace::Automaton.new(replace.keys)
    x.report "MultiStringReplace (Automaton)" do options[:iters].times { ac.replace(body, replace) } end
  else
    x.report "MultiStringReplace" do options[:iters].times { MultiStringReplace.replace(body, replace) } end
  end
  x.report "mreplace" do options[:iters].times { body.mreplace(replace) } end
end