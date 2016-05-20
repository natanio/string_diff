require "string_diff/version"
require "pragmatic_tokenizer"

module StringDiff
  class Diff
    attr_reader :string1, :string2

    def initialize(string1, string2)
      @string1 = string1
      @string2 = string2
    end

    def diff
      a1 = PragmaticTokenizer::Tokenizer.new(downcase: false).tokenize(string1)
      a2 = PragmaticTokenizer::Tokenizer.new(downcase: false).tokenize(string2)

      construct_string(compare(process_parens(a1), process_parens(a2)))
    end

    private

    def process_parens(array)
      if array.include?('(') && array.include?(')')
        array_open_parens_indexes = array.each_index.select{|i| array[i] == "("}
        array_closed_parens_indexes = array.each_index.select{|i| array[i] == ")"}

        if array_open_parens_indexes.count == array_closed_parens_indexes.count
          removed_count = 0
          array_open_parens_indexes.each do |i|
            combined_string = ""
            combined_string += (array[i-removed_count] + array[i+1-removed_count])
            array.delete_at(i-removed_count)
            array.delete_at(i-removed_count)
            array.insert(i-removed_count, combined_string)
            removed_count += 1
          end

          array_closed_parens_indexes.each do |i|
            combined_string = ""
            combined_string += (array[i-(removed_count+1)] + array[i-removed_count])
            array.delete_at(i-(removed_count+1))
            array.delete_at(i-(removed_count+1))
            array.insert(i-(removed_count+1), combined_string)
            removed_count += 1
          end
        end
      else
        array
      end
      array
    end

    def compare(array1, array2)
      deletions = array1 - array2
      puts "deletions: #{deletions.to_s}"
      insertions = array2 - array1
      puts "insertions: #{insertions.to_s}"

      process_duplicates(array1, array2)
      annotate_deletions(deletions, array1)
      annotate_insertions(insertions, array1, array2)
    end

    def annotate_deletions(deletions, array1)
      deletions.each do |v|
        index = array1.find_index(v)
        next if index.nil?
        array1[index] = "<span class='deletion'>#{v}</span>"
      end
    end

    def annotate_insertions(insertions, array1, array2)
      insertions.each_with_index do |v, i|
        if array2.find_index(v) == 0
          index = 0
        else
          insertion_position = array2.find_index(v) + i - 1
          index = array1.find_index(array2[insertion_position])
        end

        if index.nil?
          # Check whether or not we're dealing with an annotated deletion/insertion, or plain token
          contains_span = array1.last.include?("<span") ? true : false
          contains_punct_in_span = !(array1.last.scan(/(?<='>).*(?=<\/)/)[0] =~ (/[[:punct:]]/)).nil? if contains_span
          stand_alone_punct = array1.last =~ (/[[:punct:]]/) if !contains_span

          # If there is punctuation after a deletion, we need to make sure the
          # insertion is added before the punctuation.
          if (contains_punct_in_span || stand_alone_punct) && array1[-2].include?("<span class='deletion'")
            array1.insert(-2, "<span class='insertion'>#{v}</span>")
          elsif array2.find_index(v) < (PragmaticTokenizer::Tokenizer.new(downcase: false).tokenize(string1).count)
            # Count how many insertions up to the original position
            insertions_count = 0
            deletions_count = 0
            for i in 0..(array2.find_index(v)+1) do
              insertions_count += 1 if array1[i].include?("<span class='insertion'")
              deletions_count += 1 if array1[i].include?("<span class='deletion'")
            end
            array1.insert(((find_correct_index(v, array1, array2) + insertions_count + deletions_count) - 1), "<span class='insertion'>#{v}</span>")
          else
            # Otherwise we put it on the end.
             array1.insert(-1, "<span class='insertion'>#{v}</span>")
          end
        else
          array1.insert(index + 1, "<span class='insertion'>#{v}</span>")
        end
      end
      array1
    end

    def process_duplicates(array1, array2)
      dup1 = array1.find_all { |e| array1.count(e) > 1 }
      dup2 = array2.find_all { |e| array2.count(e) > 1 }

      missing_words = (dup1 - dup2).uniq
      additional_words = (dup2 - dup1).uniq

      unless additional_words.empty?
        set_additional_duplicates_indexes(array2, additional_words)
      end

      duplicate_indexs_of_array1 = []
      duplicate_indexs_of_array2 = []

      missing_words.each do |word|
        array1.each_with_index do |v, i|
          duplicate_indexs_of_array1 << i if word == v
        end

        array2.each_with_index do |v, i|
          duplicate_indexs_of_array2 << i if word == v
        end

        missing_index = duplicate_indexs_of_array1 - duplicate_indexs_of_array2

        array1[missing_index[0]] = "<span class='deletion'>#{word}</span>"
      end
    end

    def set_additional_duplicates_indexes(array, dup)
      @additional_indexes = array.each_index.select{|i| array[i] == dup[0]}
    end

    def find_correct_index(token, array1, array2)
      unless @additional_indexes.nil?
        # We need to find if the word has already been added, if so, use a later index
        appeared_count = 0
        array1.each do |item|
          appeared_count += 1 if item.include?("<span class='insertion'>#{token}")
        end

        if appeared_count == 0
          @additional_indexes[0]
        else
          @additional_indexes[appeared_count]
        end
      else
        array2.find_index(token)
      end
    end

    def construct_string(array1)
      string = ""

      array1.each_with_index do |token, i|
        if i == 0
          string += token
        else
          if token.include?("<span")
            if token.scan(/(?<='>).*(?=<\/)/)[0] !~ /[[:punct:]]/ || string1.include?(" #{token.scan(/(?<='>).*(?=<\/)/)[0]}")
              string += " #{token}"
            elsif !( token.scan(/(?<='>).*(?=<\/)/)[0] =~ (/[']/) ).nil?
              if string.scan(/[']/).empty? || string.scan(/[(]/).empty?
                string += " #{token}#{array1[i+1]}"
                array1.slice!(i+1)
              else
                string += token
              end
            elsif !( token.scan(/(?<='>).*(?=<\/)/)[0] =~ (/[(]/) ).nil?
              if string.scan(/[(]/).empty?
                string += " #{token}#{array1[i+1]}"
                array1.slice!(i+1)
              else
                string += token
              end
            else
              string += token
            end
          else
            if token !~ /[[:punct:]]/
              string += " #{token}"
            elsif !( token =~ (/[']/) ).nil?
              if string.scan(/[']/).empty?
                string += " #{token}#{array1[i+1]}"
                array1.slice!(i+1)
              else
                string += token
              end
            elsif !( token =~ (/[(]/) ).nil?
              if string.scan(/[(]/).empty?
                string += " #{token}#{array1[i+1]}"
                array1.slice!(i+1)
              else
                string += token
              end
            else
              string += token
            end
          end
        end
      end
      string
    end
  end
end