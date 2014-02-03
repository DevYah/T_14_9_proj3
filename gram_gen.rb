module GramGen

  # ==================== SKELETON START ====================
  def self.gen_file(sentences, file_name)
    grammar = gen(sentences)
    gram_name = file_name[0, file_name.index('.')]
    file_string = make_file_string(grammar, gram_name)
    file = File.new(file_name, 'w')
    file.write(file_string)
    file.close
  end

  # groups sentences according to length,
  # for each group generate rules.
  def self.gen(sentences)
    # groups sentences according to length,
    splitted = sentences.map(&:split)
    groups = splitted.group_by(&:size).values
    rules = []
    # for each group generate rules (of maximum one option set)
    groups.each do |group|
      new_rules = generalize(group)
      rules += new_rules
    end
    # takes set of rules and tries to generate a smaller set of rules
    # equivalent with maximum two option sets
    generalize_rules!(rules)
    return rules
  end
  # ==================== SKELETON END ====================


  # ====================  FIRST GENERALIZATION START ====================
  # splits group to minimum number of groups so that each smaller group can
  # be represented by a rule with only option set.  Returns the set of rules
  # representing the group
  def self.generalize(group)
    size = group[0].size
    rule = ['NA'] * size
    rules = []
    options_index = -1
    (0...size).each do |index|
      words = group.map {|sen| sen[index]}
      words.uniq!
      if words.size == 1
        rule[index] = words[0]
        rules.each {|r| r[index] = words[0]}
      elsif options_index == -1
        rule[index] = words
        options_index = index
      else
        hash, groups = get_options_hash(rule[options_index], options_index,
                                        index, group)
        prune_hash!(hash)
        if groups.size != 1
          new_rules = []
          groups.each do |group|
            new_rules += generalize(group)
          end
        elsif !rule[0...index].include?('NA')
          new_rules = hash.map do |key, value|
            new_rule = rule.dup
            if key.size == 1
              new_rule[options_index] = key[0]
            else
              new_rule[options_index] = key
            end
            second_options = value

            if second_options.size == 1
              rule[index] = second_options[0]
              new_rule[index] = second_options[0]
            else
              rule[index] = second_options
              new_rule[index] = second_options
            end
            new_rule
          end
        else
          new_rules = []
        end
        rules += new_rules
      end
    end
    rules = rules != [] ? rules : [rule]

    clean_up_NAs(rules)
  end

  def self.prune_hash!(hash)
    # for all keys, if any word in the key1 (with value1) exist in another
    # key key2 (with value2) where the value2 is a subset from value1, remove
    # word from key2
    replace = {}
    hash.each do |key1, value1|
      key1.each do |word|
        key_values = hash.select {|key2, _| key2.include?(word) && key2 != key1}
        key_values.select! {|key2, value2| value2-value1 == []}
        key_values.keys.each do |key2|
          new_key2 = key2 - [word]
          replace[key2] = new_key2
        end
      end
    end
    replace.each do |k,v|
      hash[v] = hash[k]
      hash.delete(k)
    end
  end

  def self.get_options_hash(words, index, options_at, sentences)
    hash = {}
    words.each do |word|
      hash[word] = get_options(word, index, options_at, sentences)
    end

    new_hash = {}
    hash.values.each do |value|
      keys = []
      hash.each do |k,v|
        if value - v == [] && v - value == []
          keys << k
        end
      end
      new_hash[keys] = value
    end
    groups = new_hash.map do |k,v|
      k = k.is_a?(Array) ? k : [k]
      sen = sentences.select {|sen| k.include?(sen[index]) &&
                              v.include?(sen[options_at])}
      sen
    end
    [new_hash, groups]
  end

  def self.get_options(word, word_at, options_at, splitted_sentences)
    valid_sentences = splitted_sentences.select {|sen| sen[word_at] == word}
    valid_sentences.map {|sen| sen[options_at]}.uniq
  end

  def self.clean_up_NAs(new_rules)
    new_rules.select {|rule| !rule.include?('NA')}
  end
  # ====================  FIRST GENERALIZATION  END ====================




  # ====================  SECOND GENERALIZATION START ====================
  # Keeps checking all pairs of rules and tries unifying them using unify
  # until there's no change or no further unification possible.
  def self.generalize_rules!(rules)
    begin
      fixed_point = true
      for i in (0..rules.size)
        for j in (i+1...rules.size)
          if new_rule = unify(rules[i], rules[j])
            rules.delete_at(i)
            rules.delete_at(j-1)
            rules << new_rule
            i,j = 0,0
            fixed_point = false
          end
        end
      end
    end while !fixed_point
  end

  # Checks for rules with only one common option set and only one
  # difference in the same index to get a unified rule
  # combining that different index into an option set.
  def self.unify(rule1, rule2)
    return false if rule1.size != rule2.size
    option1_ind = rule1.index(rule1.find{|s| s.is_a?(Array)})
    option2_ind = rule2.index(rule2.find{|s| s.is_a?(Array)})
    return false if option1_ind != option2_ind
    matching_indices = get_matching_indices(rule1, rule2)
    different = (0...rule1.size).to_a - matching_indices
    return false if different.size > 1
    new_rule = rule1.dup
    new_rule[different[0]] = [rule1[different[0]], rule2[different[0]]].flatten
    new_rule
  end

  # Gets an array of indices sharing the same values between both rules.
  def self.get_matching_indices(rule1, rule2)
    matching = []
    (0...rule1.size).each do |i|
      matching << i if rule1[i] == rule2[i]
    end
    matching
  end
  # ====================  SECOND GENERALIZATION END  ====================


  # ====================  PRESENTATION START ==================
  def self.pretty_format_rule(rule)
    s = ''
    if rule.is_a?(String)
      s = rule.strip!
    else
      rule.each do |cell|
        if cell.is_a? Array
          s += "(#{cell.join('|')}) "
        else
          s+= "#{cell} "
        end
      end
      s.strip!
    end
    s
  end

  def self.print_gr(grammar)
    grammar.each do |rule|
      p pretty_format_rule(rule)
    end
  end

  def self.print_group(group)
    puts group.map{|s| s.join(" ")}
  end

  def self.make_file_string(grammar, grammar_name)
    s = "\\\\ AUTO-GENERATED GRAMMAR\n\n\n"
    s += "grammar #{grammar_name};\n"
    grammar.each_with_index do |rule, index|
      s+= "public <rule#{index}> = #{pretty_format_rule(rule)};\n"
    end
    return s
  end
  # ====================  PRESENTATION END ====================

end

if ARGV.count == 2
  input_file = ARGV[0]
  output_file = ARGV[1]
  sentences = File.new(input_file).read.split("\n")
  GramGen.gen_file(sentences, output_file)
  puts "Grammar written to #{output_file} from sentences in #{input_file}"
end
