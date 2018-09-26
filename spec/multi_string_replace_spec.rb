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

  it "Replace instances of keys with replacements" do
    sub = MultiStringReplace::Substitution.new(%w(brown jumps))
    expect(sub.process("The quick brown fox jumps over the lazy dog", { 'brown' => 'black', 'jumps' => 'hops'})).to eq("The quick black fox hops over the lazy dog")

    sub = MultiStringReplace::Substitution.new(%w(brown black rutrum sapien sellis))
    expect(sub.process(body, { 'brown' => 'dolor', 'black' => 'elit', "rutrum" => "tempor", "sellis" => "commodo"})).to eq(
          "Lorem ipsum dolor sit amet, consectetur dolor elit. Proin vehicula dolor egestas." + 
          "Aliquam a dui tincidunt, elementum  in, ultricies lacus. Phasellus congue,  necconsectetur" +
          " tempor, eros ex ullamcorper orci, in lobortis turpis mi et odio. Sed commodo a quam elementum, quis fringilla mi pulvinar. Aenean cursus  at tempor commodo.Aliquam ultrices dapibus ante, eu volutpat nisi dictum eget. Vivamus commodo ipsum tellus, vitae tempor diam fermentum ut.")
  end

  it "Allows preprocessing to speed up character replacements" do
    sub = MultiStringReplace::Substitution.new(%w(brown black rutrum sapien sellis)).for(body)
    expect(sub.process({'brown' => 'dolor', 'black' => 'elit', "rutrum" => "tempor", "sellis" => "commodo"})).to eq(
      "Lorem ipsum dolor sit amet, consectetur dolor elit. Proin vehicula dolor egestas." + 
      "Aliquam a dui tincidunt, elementum  in, ultricies lacus. Phasellus congue,  necconsectetur" +
      " tempor, eros ex ullamcorper orci, in lobortis turpis mi et odio. Sed commodo a quam elementum, quis fringilla mi pulvinar. Aenean cursus  at tempor commodo.Aliquam ultrices dapibus ante, eu volutpat nisi dictum eget. Vivamus commodo ipsum tellus, vitae tempor diam fermentum ut.")
  end

  context ".match" do
    it "returns matched indexes in the string" do
      sub = MultiStringReplace::Substitution.new(%w(brown jumps))
      expect(sub.match("The quick brown fox jumps over the lazy dog")).to eq({"brown"=>[10], "jumps"=>[20]})
    end
  end

  specify "native extension" do
    puts MultiStringReplaceExt.match("The quick brown fox jumps over the lazy dog", ['brown', 'fox'])
  end
end
