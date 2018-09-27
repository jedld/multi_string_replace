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
    end

  specify ".replace" do
    expect(MultiStringReplace.replace("The quick brown fox jumps over the lazy dog brown", {'brown' => 'black', 'fox' => 'wolf'})).
        to eq("The quick black wolf jumps over the lazy dog black")
  end

  specify ".replace with proc" do
    expect(MultiStringReplace.replace("The quick brown fox jumps over the lazy dog brown", {'brown' => 'black', 'fox' => ->() { "cat" }})).
        to eq("The quick black cat jumps over the lazy dog black")
  end
end
