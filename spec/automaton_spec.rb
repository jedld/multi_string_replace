require 'spec_helper'
RSpec.describe MultiStringReplace::Automaton do
  it 'matches with compiled automaton' do
    ac = described_class.new(['brown', 'fox'])
    res = ac.match('The quick brown fox')
    expect(res).to be_a(Hash)
    # ids 0 and 1 should exist with positions
    expect(res[0]).to include(10) # 'brown'
    expect(res[1]).to include(16) # 'fox'
  end

  it 'replaces with compiled automaton' do
    ac = described_class.new(['brown', 'fox'])
    out = ac.replace('The quick brown fox', { 'brown' => 'black', 'fox' => 'wolf' })
    expect(out).to eq('The quick black wolf')
  end

  it 'falls back to original when no replacement provided' do
    ac = described_class.new(['brown'])
    out = ac.replace('brown', {})
    expect(out).to eq('brown')
  end

  it 'supports proc values' do
    ac = described_class.new(['x'])
    out = ac.replace('xx', { 'x' => ->(s, e) { 'y' } })
    expect(out).to eq('yy')
  end
end
