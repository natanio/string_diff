require 'spec_helper'

describe StringDiff do
  it 'has a version number' do
    expect(StringDiff::VERSION).not_to be nil
  end

  it 'annotates insertions' do
    string_1 = "hello world"
    string_2 ="hello beautiful world"
    sd = StringDiff::Diff.new(string_1, string_2).diff

    expect(sd).to eq("hello <span class='insertion'>beautiful</span> world")
  end

  it 'annotates deletions' do
    string_1 = "hello world"
    string_2 = "hello"
    sd = StringDiff::Diff.new(string_1, string_2).diff

    expect(sd).to eq("hello <span class='deletion'>world</span>")
  end

  it 'handles an insertion and deletion' do
    string_1 = "hello beautiful world"
    string_2 = "hello world friends"
    sd = StringDiff::Diff.new(string_1, string_2).diff

    expect(sd).to eq("hello <span class='deletion'>beautiful</span> world <span class='insertion'>friends</span>")
  end

  it 'handles the same word twice' do
    string_1 = "hello beautiful world hello"
    string_2 = "hello beautiful world"
    sd = StringDiff::Diff.new(string_1, string_2).diff

    expect(sd).to eq("hello beautiful world <span class='deletion'>hello</span>")
  end

  it 'inserts the same word twice' do
    string_1 = "hello world"
    string_2 = "hello beautiful world beautiful people"
    sd = StringDiff::Diff.new(string_1, string_2).diff

    expect(sd).to eq("hello <span class='insertion'>beautiful</span> world <span class='insertion'>beautiful</span> <span class='insertion'>people</span>")
  end

  it 'deletes punctuation' do
    string_1 = "hello - world"
    string_2 = "hello world"
    sd = StringDiff::Diff.new(string_1, string_2).diff

    expect(sd).to eq("hello <span class='deletion'>-</span> world")
  end

  it 'inserts punctuation' do
    string_1 = "hello world"
    string_2 = "hello, world!"
    sd = StringDiff::Diff.new(string_1, string_2).diff

    expect(sd).to eq("hello<span class='insertion'>,</span> world<span class='insertion'>!</span>")
  end

  it 'should handle capitalization' do
    string_1 = "hello world"
    string_2 = "Hello world"
    sd = StringDiff::Diff.new(string_1, string_2).diff

    expect(sd).to eq("<span class='deletion'>hello</span> <span class='insertion'>Hello</span> world")
  end

end