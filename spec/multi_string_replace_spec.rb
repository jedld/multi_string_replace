RSpec.describe MultiStringReplace do
  let(:body) {
    "Lorem ipsum dolor sit amet, consectetur brown elit. Proin vehicula brown egestas." + 
    "Aliquam a dui tincidunt, elementum sapien in, ultricies lacus. Phasellus congue, sapien nec" +
    "consectetur rutrum, eros ex ullamcorper orci, in lobortis turpis mi et odio. Sed sellis" +
    "sapien a quam elementum, quis fringilla mi pulvinar. Aenean cursus sapien at rutrum commodo." +
    "Aliquam ultrices dapibus ante, eu volutpat nisi dictum eget. Vivamus sellis ipsum tellus, vitae tempor diam fermentum ut."
  }

  it "has a version number" do
    expect(MultiStringReplace::VERSION).not_to be nil
  end

  specify ".match" do
    expect(MultiStringReplace.
      match("The quick brown fox jumps over the lazy dog brown", ['brown', 'fox'])).to eq({
        0 => [10, 44],
        1 => [16]
      })

    expect(MultiStringReplace.
      match(body,%w(consectetur rutrum))).to eq({
        0 => [28, 172],
        1 => [184, 336],
      })

    expect(MultiStringReplace.
      match(body,%i(consectetur rutrum))).to eq({
        0 => [28, 172],
        1 => [184, 336],
      })

      expect(MultiStringReplace.
        match("The quick brown brave fox jumps over the lazy dog brown", ['brown', 'fox', 'brave'])).to eq({
          0 => [10, 50],
          1 => [22],
          2 => [16],
        })  
  end

  specify "no matches" do
    expect(MultiStringReplace.
      match(body,%w(yyyyy bbbbbb))).to eq({})
  end

  specify ".replace" do
    expect(MultiStringReplace.replace("The quick brown fox jumps over the lazy dog brown", {'brown' => 'black', 'fox' => 'wolf'})).
        to eq("The quick black wolf jumps over the lazy dog black")

    expect(MultiStringReplace.replace(body, 'fermentum ut.' => '')).to eq("Lorem ipsum dolor sit amet, consectetur brown elit. Proin vehicula brown egestas.Aliquam a dui tincidunt, elementum sapien in, ultricies lacus. Phasellus congue, sapien necconsectetur rutrum, eros ex ullamcorper orci, in lobortis turpis mi et odio. Sed sellissapien a quam elementum, quis fringilla mi pulvinar. Aenean cursus sapien at rutrum commodo.Aliquam ultrices dapibus ante, eu volutpat nisi dictum eget. Vivamus sellis ipsum tellus, vitae tempor diam ")
  end

  specify ".replace with proc" do
    expect(MultiStringReplace.replace("The quick brown fox jumps over the lazy dog brown", {'brown' => 'black', 'fox' => ->() { "cat" }})).
        to eq("The quick black cat jumps over the lazy dog black")
  end

  specify ".replace nothing to replace" do
    expect(body.mreplace({'XXXXXXXXX' => 'yyyyyyyy'})). to eq(body)
  end

  specify "String patches" do
    expect(body.mreplace({ 'Lorem' => 'Replace1', 'consectetur' => 'consecutive'})).to eq("Replace1 ipsum dolor sit amet, consecutive brown elit. Proin vehicula brown egestas.Aliquam a dui tincidunt, elementum sapien in, ultricies lacus. Phasellus congue, sapien necconsecutive rutrum, eros ex ullamcorper orci, in lobortis turpis mi et odio. Sed sellissapien a quam elementum, quis fringilla mi pulvinar. Aenean cursus sapien at rutrum commodo.Aliquam ultrices dapibus ante, eu volutpat nisi dictum eget. Vivamus sellis ipsum tellus, vitae tempor diam fermentum ut.")
    expect(body.mreplace({ 'Lorem' => ->() {'Replace2'}, 'consectetur' => 'consecutive'})).to eq("Replace2 ipsum dolor sit amet, consecutive brown elit. Proin vehicula brown egestas.Aliquam a dui tincidunt, elementum sapien in, ultricies lacus. Phasellus congue, sapien necconsecutive rutrum, eros ex ullamcorper orci, in lobortis turpis mi et odio. Sed sellissapien a quam elementum, quis fringilla mi pulvinar. Aenean cursus sapien at rutrum commodo.Aliquam ultrices dapibus ante, eu volutpat nisi dictum eget. Vivamus sellis ipsum tellus, vitae tempor diam fermentum ut.")
  end

  context "gsub equivalency test" do
    let(:replace_hash) do
      tokens = body.gsub("\.",' ').gsub("\,",' ').split(' ').uniq.reject { |t| t.size < 7 }
      random_keys = tokens.shuffle
      random_values = tokens.shuffle
      random_keys.zip(random_values).collect do |x,y|
        [x, y]
      end.to_h
    end

    it "should be equal" do
      puts replace_hash
      body_per_line = body.gsub(' ', "\n") # to make it easier to debug
      puts body_per_line
      gsub_value = body_per_line.gsub(/(#{replace_hash.keys.map{ |k| Regexp.quote(k) }.join('|')})/, replace_hash)
      mreplace_value = body_per_line.mreplace(replace_hash)

      expect(mreplace_value).to eq(gsub_value)
    end
  end
end
