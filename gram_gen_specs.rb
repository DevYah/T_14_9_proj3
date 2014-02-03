require_relative './gram_gen.rb'

describe GramGen do
  before(:all) do
    GG = GramGen
  end
  it 'should get options' do
    s1 = 'The boy loves girls'
    s2 = 'The boy loves milk'
    s3 = 'The man loves girls'
    s4 = 'The dog loves mice'
    s5 = 'The cat loves mice'
    list = [s1, s2, s3, s4, s5]
    list.map! {|s| s.split}

    options = GramGen.get_options('boy', 1, 3, list)
    options.should == ['girls', 'milk']

    options = GramGen.get_options('man', 1, 3, list)
    options.should == ['girls']
  end

  it 'should generate grammar (SIMPLE)' do
    s1 = 'The boy loves girls'
    s2 = 'The man loves girls'
    s3 = 'The dog loves mice'
    s4 = 'The cat loves mice'
    list = [s1, s2, s3, s4]
    grammar = GramGen.gen(list)
    #p grammar
    grammar.size == 2
    GG.pretty_format_rule(grammar[0]).strip.should == 'The (boy|man) loves girls'
    GG.pretty_format_rule(grammar[1]).strip.should == 'The (dog|cat) loves mice'
  end

  it 'should generate grammar (Medium)' do
    s1 = 'The boy loves girls too'
    s2 = 'The man loves girls too'
    s3 = 'The dog loves mice too'
    s4 = 'The cat loves mice too'
    list = [s1, s2, s3, s4]
    grammar = GramGen.gen(list)
    grammar.size == 2

    formats = grammar.map{|r|  GG.pretty_format_rule(r)}
    p formats
    formats.include?('The (boy|man) loves girls too').should be_true
    formats.include?('The (dog|cat) loves mice too').should be_true
  end

  it 'should generate grammar (Medium2)' do
    s1 = 'The boy loves girls too'
    s2 = 'The man loves girls too'
    s3 = 'The dog loves mice too'
    s4 = 'The cat loves mice too'
    s5 = 'We all love mice'
    s6 = 'We all love cats'
    s7 = 'We all hate mice'
    s8 = 'We all hate cats'

    list = [s1, s2, s3, s4, s5, s6, s7, s8]
    grammar = GramGen.gen(list)
    grammar.size.should == 3

    formats = grammar.map{|r|  GG.pretty_format_rule(r)}
    formats.include?('The (boy|man) loves girls too').should be_true
    formats.include?('The (dog|cat) loves mice too').should be_true
    formats.include?('We all (love|hate) (mice|cats)').should be_true
  end

  it 'should generate grammar (Medium3)' do
    s1 = 'We all love mice'
    s2 = 'We all love cats'
    s3 = 'We all hate mice'
    list = [s1, s2, s3]

    grammar = GramGen.gen(list)
    grammar.size.should == 2

    formats = grammar.map{|r|  GG.pretty_format_rule(r)}
    formats.include?('We all love (mice|cats)').should be_true
    formats.include?('We all hate mice').should be_true
  end
  it 'should generate grammar (hard1)' do
    # we [all|now] love [mice|cats]
    # we all hate mice
    s1 = 'We all love mice'
    s2 = 'We all love cats'

    s3 = 'We now love mice'
    s4 = 'We now love cats'
    s5 = 'We all hate mice'

    list = [s1, s2, s3, s4, s5]

    grammar = GramGen.gen(list)
    grammar.size.should == 2

    formats = grammar.map{|r|  GG.pretty_format_rule(r)}
    formats.include?('We (all|now) love (mice|cats)').should be_true
    formats.include?('We all hate mice').should be_true
   end

  it 'should gen grammar game' do
    list = [
      'change tile 1',
      'change tile 2',
      'change tile 3',
      'change tile 4', 
      'rotate tile clockwise',
      'rotate tile anti-clockwise',
      'fix tile'
    ]

    grammar = GramGen.gen(list)
    #GG.print_gr(grammar)
    grammar.size.should == 3

    formats = grammar.map{|r|  GG.pretty_format_rule(r)}
    formats.include?('change tile (1|2|3|4)').should be_true
    formats.include?('rotate tile (clockwise|anti-clockwise)').should be_true
    formats.include?('fix tile').should be_true
  end

  it 'should gen grammar light' do
    list = [
      'light is off',
      'light is on',
      'lights are off',
      'lights are on',
    ]

    grammar = GramGen.gen(list)
    #GG.print_gr(grammar)
    grammar.size.should == 2

    formats = grammar.map{|r|  GG.pretty_format_rule(r)}
    formats.include?('light is (off|on)').should be_true
    formats.include?('lights are (off|on)').should be_true
    #puts GG.make_file_string(grammar, 'za3bola')
  end
end
