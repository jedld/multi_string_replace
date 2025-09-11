require "spec_helper"

RSpec.describe "Consistency" do
  it "Automaton#replace matches .replace for random inputs" do
    srand(1234)
    10.times do
      keys = Array.new(10) { (0...rand(1..5)).map { ('a'.ord + rand(26)).chr }.join }
      keys.uniq!
      replacements = keys.map { |k| [k, (0...rand(0..6)).map { ('a'.ord + rand(26)).chr }.join] }.to_h
      body = Array.new(500) { ('a'.ord + rand(26)).chr }.join

      auto = MultiStringReplace::Automaton.new(keys)
      expect(auto.replace(body, replacements)).to eq(MultiStringReplace.replace(body, replacements))
    end
  end
end
