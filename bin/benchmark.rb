require "bundler/setup"
require 'multi_string_replace'
require 'benchmark'

class String
  def mgsub(key_value_pairs=[].freeze)
    regexp_fragments = key_value_pairs.collect { |k,v| k }
    gsub( 
Regexp.union(*regexp_fragments)) do |match|
      key_value_pairs.detect{|k,v| k =~ match}[1]
    end
  end
end

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
  'cursus' => '乧乨乩乪乫乬乭乮乯买乱乲乳乴乵乶乷乸乹乺乻乼乽乾乿',
  'Vivamus' => '㐀㐁㐂㐃㐄㐅㐆㐇㐈㐉㐊㐋'
}

File.write('replaced.txt', body.gsub(/(#{replace.keys.join('|')})/, replace))
File.write('replaced2.txt', MultiStringReplace.replace(body, replace))

Benchmark.bmbm do |x|
  x.report "multi gsub" do 100.times { body.mgsub(replace.map { |k, v| [/#{k}/, v] } ) } end
  x.report "MultiStringReplace" do 100.times { MultiStringReplace.replace(body, replace) } end
  x.report "mreplace" do 100.times { body.mreplace(replace) } end
end