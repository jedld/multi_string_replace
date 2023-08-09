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
    expect(MultiStringReplace.replace("The quick brown fox jumps over the lazy dog brown", {'brown' => 'black', 'fox' => 'wolf', 'the' => 0})).
        to eq("The quick black wolf jumps over 0 lazy dog black")

    expect(MultiStringReplace.replace(body, 'fermentum ut.' => '')).to eq("Lorem ipsum dolor sit amet, consectetur brown elit. Proin vehicula brown egestas.Aliquam a dui tincidunt, elementum sapien in, ultricies lacus. Phasellus congue, sapien necconsectetur rutrum, eros ex ullamcorper orci, in lobortis turpis mi et odio. Sed sellissapien a quam elementum, quis fringilla mi pulvinar. Aenean cursus sapien at rutrum commodo.Aliquam ultrices dapibus ante, eu volutpat nisi dictum eget. Vivamus sellis ipsum tellus, vitae tempor diam ")
  end

  context "replace using proc" do
    specify ".replace with proc" do
      expect(MultiStringReplace.replace("The quick brown fox jumps over the lazy dog brown", {'brown' => 'black', 'fox' => ->(_, _) { "cat" }})).
          to eq("The quick black cat jumps over the lazy dog black")
    end

    specify ".replace with proc should provide match index" do
      expect(MultiStringReplace.replace("The quick brown fox jumps over the lazy dog brown", {'fox' => ->(s, e) {
          expect(s).to eq 16
          expect(e).to eq 19
        "cat"
        }, 
        "jumps" => ->(s, e) {
          expect(s).to eq 20
          expect(e).to eq 25
          "rat"
        }
        })).to eq("The quick brown cat rat over the lazy dog brown")
    end

    specify ".replace returning nil should not change the string" do
      expect(MultiStringReplace.replace("The quick brown fox jumps over the lazy dog brown", {'fox' => ->(s, e) { nil }}))
      .to eq("The quick brown fox jumps over the lazy dog brown")
    end

    specify ".replace returning '' should remove the string" do
      expect(MultiStringReplace.replace("The quick brown fox jumps over the 0 dog brown", {'brown' => 'black', 
        'fox' => ->(s, e) { "" },
        'lazy' => -> (s, e) { 0 }
        }))
        .to eq("The quick black  jumps over the 0 dog black")
    end
  end

  specify ".replace nothing to replace" do
    expect(body.mreplace({'XXXXXXXXX' => 'yyyyyyyy'})). to eq(body)
  end

  specify "String patches" do
    expect(body.mreplace({ 'Lorem' => 'Replace1', 'consectetur' => 'consecutive'})).to eq("Replace1 ipsum dolor sit amet, consecutive brown elit. Proin vehicula brown egestas.Aliquam a dui tincidunt, elementum sapien in, ultricies lacus. Phasellus congue, sapien necconsecutive rutrum, eros ex ullamcorper orci, in lobortis turpis mi et odio. Sed sellissapien a quam elementum, quis fringilla mi pulvinar. Aenean cursus sapien at rutrum commodo.Aliquam ultrices dapibus ante, eu volutpat nisi dictum eget. Vivamus sellis ipsum tellus, vitae tempor diam fermentum ut.")
    expect(body.mreplace({ 'Lorem' => ->(_, _) {'Replace2'}, 'consectetur' => 'consecutive'})).to eq("Replace2 ipsum dolor sit amet, consecutive brown elit. Proin vehicula brown egestas.Aliquam a dui tincidunt, elementum sapien in, ultricies lacus. Phasellus congue, sapien necconsecutive rutrum, eros ex ullamcorper orci, in lobortis turpis mi et odio. Sed sellissapien a quam elementum, quis fringilla mi pulvinar. Aenean cursus sapien at rutrum commodo.Aliquam ultrices dapibus ante, eu volutpat nisi dictum eget. Vivamus sellis ipsum tellus, vitae tempor diam fermentum ut.")
  end

  # https://github.com/jedld/multi_string_replace/issues/3
  specify "fix newline behavior" do
    expect(MultiStringReplace.replace("string ends with a replace", { 'replace': '123' })).to eq("string ends with a 123")
    expect(MultiStringReplace.replace("string ends with a replace\n", { 'replace': '123' })).to eq("string ends with a 123\n")
    expect(MultiStringReplace.replace("string ends with a replacex", { 'replace': '123' })).to eq("string ends with a 123x")
  end

  specify "edge cases" do
    expect(MultiStringReplace.replace("string ends with a replace", { 'string': '123' })).to eq("123 ends with a replace")
    expect(MultiStringReplace.replace("xstring ends with a replace", { 'string': '123' })).to eq("x123 ends with a replace")
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

  context "non-ascii characters" do
    it "shouldn't crash on binary characters" do
      expect(MultiStringReplace.replace("", {"\xE9" => ""})).to eq("")
    end
  end
end
