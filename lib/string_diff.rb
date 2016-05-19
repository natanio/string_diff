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

      construct_string(compare(a1, a2))
    end

    private

    def compare(array1, array2)
      deletions = array1 - array2
      insertions = array2 - array1

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
          puts "Index is nil"
          puts array1.to_s

          # If there is punctuation after a deletion, we need to make sure the
          # insertion is added before the punctuation.
          if (!(array1.last.scan(/(?<='>).*(?=<\/)/)[0] =~ (/[[:punct:]]/)).nil? || (array1.last =~ (/[[:punct:]]/))) && array1[-2].include?("<span class='deletion'")
            puts "Block 1"
            array1.insert(-2, "<span class='insertion'>#{v}</span>")
          elsif array2.find_index(v) <= (PragmaticTokenizer::Tokenizer.new(downcase: false).tokenize(string1).count)
            puts "Block 2"

            # Count how many insertions up to the original position
            insertions_count = 0
            deletions_count = 0
            for i in 0...(array2.find_index(v)+1) do
              puts array2.find_index(v)
              puts i
              puts v
              puts array1[i].to_s
              puts "array1 insertions test is #{array1[i].include?("<span class='insertion'")}"
              insertions_count += 1 if array1[i].include?("<span class='insertion'")
              deletions_count += 1 if array1[i].include?("<span class='deletion'")
            end
            puts "Insertion count: #{insertions_count}"
            puts "Deletion count: #{deletions_count}"
            puts "index: #{array2.find_index(v)}"
            array1.insert(((array2.find_index(v) + insertions_count + deletions_count) - 1), "<span class='insertion'>#{v}</span>")
          else
            # Otherwise we put it on the end.
            puts "Block 3"
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

    def construct_string(array1)
      string = ""

      array1.each_with_index do |token, i|
        if i == 0
          string += token
        else
          puts token
          if token.include?("<span")
            if token.scan(/(?<='>).*(?=<\/)/)[0] !~ /[[:punct:]]/ || string1.include?(" #{token.scan(/(?<='>).*(?=<\/)/)[0]}")
              string += " #{token}"
            elsif !( token.scan(/(?<='>).*(?=<\/)/)[0] =~ (/[']/) ).nil?
              if string.scan(/[']/).empty?
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


# def annotate_insertions(insertions, array1, array2)
#   insertions.each_with_index do |v, i|
#     if array2.find_index(v) == 0
#       index = 0
#     else
#       insertion_position = array2.find_index(v) + i - 1
#       index = array1.find_index(array2[insertion_position])
#     end

#     if index.nil?
#       puts "Index is nil"
#       # If there is punctuation after a deletion, we need to make sure the
#       # insertion is added before the punctuation.
#       if !(array1.last.scan(/(?<='>).*(?=<\/)/)[0] =~ (/[[:punct:]]/)).nil? && array1[-2].include?("<span class='deletion'")
#         puts "Block 1"
#         array1.insert(-2, "<span class='insertion'>#{v}</span>")
#       elsif array2.find_index(v) >= (PragmaticTokenizer::Tokenizer.new(downcase: false).tokenize(string1).count -1)
#         puts "Block 2"
#         array1.insert(-1, "<span class='insertion'>#{v}</span>")
#       else
#         # Otherwise we put it on the end.
#         puts "Block 3"
#         # Count how many insertions up to the original position
#         insertions_count = 0
#         for i in 0...(array2.find_index(v)+1) do
#           puts array2.find_index(v)
#           puts i
#           puts v
#           puts array1[i].to_s
#           puts "array1 insertions test is #{array1[i].include?("<span class='insertion'")}"
#           insertions_count += 1 if array1[i].include?("<span class='insertion'")
#         end
#         puts "Insertion count: #{insertions_count}"
#         array1.insert((array2.find_index(v) + insertions_count), "<span class='insertion'>#{v}</span>")


#         # puts array1.to_s
#         # puts array1.count
#         # puts v
#         # array1.insert((array1.count -1), "<span class='insertion'>#{v}</span>")
#       end
#     else
#       array1.insert(index + 1, "<span class='insertion'>#{v}</span>")
#     end
#   end

#   array1
# end
