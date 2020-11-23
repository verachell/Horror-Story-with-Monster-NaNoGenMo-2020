require 'set'

#################################
###     GENERAL FUNCTIONS     ### 
#################################
def file_2_set(subdirectory)
  # given a file in a directory, this will return a set with
  # each line of the file as an item of the set
  lambda {|filename|
    setname = Set.new
    fullname = subdirectory + "/" + filename
    if File.exists?(fullname) then
      IO.foreach(fullname){|theline|setname << theline.chomp}
      setname.delete("")
    else
      abort "STOPPING: SERIOUS ERROR. File: #{filename} not found in subdirectory: #{subdirectory}"
    end
    return setname}
end

def word_count_str(thestring)
  # returns word count of a string. This will typically be 1 sentence.
  result = thestring.strip.count(" ") + 1
  # exclude from counting markdown formatting characters or a dash as words
  if thestring.include?("#") then result = result - 1 end
  return result
end

def word_count_all(arr_of_string)
  arr_of_string.inject(0) {|tot, sentences| tot + word_count_str(sentences)}
end

def get_randoms(unique, howmany, theset, exclude=[])
  # returns a set of items. If no items are found, returns empty set.
  # Be careful using the unique option: if too many unique items are requested
  # compared to size of theset after exclusions are removed, the returned set
  # will be smaller than requested and may even be empty.
  result = Set[]
  tempset = theset - exclude
  howmany.times {
    if tempset.empty? == false then
      thearr = tempset.to_a
      tempitem = thearr[rand(thearr.size)]
      result << tempitem
      if unique == true then
        tempset.delete(tempitem)
      end
    end
  }
  return result
end

# generate variants of the above function via partial application of parameters
select_randoms = self.method(:get_randoms).curry
select_randoms_uniques = select_randoms.call(true)
select_one = select_randoms.call(false, 1)
select_two_unique = select_randoms.call(true, 2)
# bear in mind select_one returns a set of 1 member, so to get the item need to append .to_a[0]

##################################################################
### ALL THE FUNCTIONS WHICH HANDLE SENTENCE OR PLOT GENERATION ###
##################################################################
def arr_2_sentence(thearr)
  # takes an array with 2 or more items and returns the items as a string
  # listed in the following format: __, __ and ___
  result = ""
  thearr.each_with_index{|x, ind|
    if ind < thearr.size - 2 then
      tempstr = ", "
    elsif ind == thearr.size - 2 then
      tempstr = " and "
    else
      tempstr = ""
    end
    result.concat(x, tempstr)}
  return result
end

def generate_characters(number_people, malenames, femalenames, occupations, verbs)
  # returns an array of characters, each of which is a hash containing character info
  result = Array.new(number_people) {Hash.new}
  allnames = malenames + femalenames
  people_names = get_randoms(true, number_people, allnames).to_a
  people_jobs = get_randoms(true, number_people, occupations).to_a
  people_verb = get_randoms(true, number_people, verbs).to_a
  people_familyfriends = Array.new(number_people, Set.new)
  people_familyfriends.collect!{|x| x = get_randoms(true, 2, allnames) + ["Mom", "Dad"]}
  result.each{|character|
    character[:"name"] = people_names.pop
    if malenames.member?(character[:"name"]) then
      character[:"gender"] = "M"
      character[:"heshe"] = "he"
      character[:"himher"] = "him"
    else
      character[:"gender"] = "F"
      character[:"heshe"] = "she"
      character[:"himher"] = "her"
    end
    character[:"job"] = people_jobs.pop
    character[:"fave_verb"] = people_verb.pop
    character[:"familyfriends"] = people_familyfriends.pop
  }
  return result
end

def ispart(sentence, changed_sentence_type, changing_sentences)
  # returns a boolean value depending on whether the queried sentence is
  # a member of the changed_sentence_type specified in changing_sentences
  result = false
  if (changing_sentences.empty? == false) and changing_sentences.has_key?(changed_sentence_type.to_sym) then
    that_type = changing_sentences[changed_sentence_type.to_sym]
    if changing_sentences.empty? == false then
      that_type.each{|x| if x.member?(sentence) then result = true end}
    end
  end
  return result
end

def distribute_3_sets(curr_wc, the3setarr, tot_expected_wc)
  # takes 3 sets and and returns 1 set with elements of 2 sets.
  # the returned elements depends upon the current word count as a proportion
  # of toal word count. This is the mechanism by which the story vocabulary
  # evolves over time. The 3 sets may be words, sentences, or anything else.
  halfway = tot_expected_wc/2
  if curr_wc < halfway then
    spoint = 0
    epoint = halfway
    decreasing = the3setarr[0]
    increasing = the3setarr[1]
  else
    spoint = halfway
    epoint = tot_expected_wc
    decreasing = the3setarr[1]
    increasing = the3setarr[2]
  end
  deltainc = (curr_wc - spoint).to_f
  deltadec = (epoint - curr_wc).to_f
  numincitems = ((deltainc / halfway.to_f) * increasing.size.to_f).to_i
  numdecitems = ((deltadec / halfway.to_f) * decreasing.size.to_f).to_i
  get_randoms(true, numincitems, increasing) + get_randoms(true, numdecitems, decreasing)
end

def nopunctuation(one_sentence)
  # returns true if there are only alphabetical characters at end of sentence
  one_sentence.match?(/[[:alpha:]]/, (one_sentence.size - 1))
end

def add_period(one_sentence)
  # returns sentence with period added if necessary
  if nopunctuation(one_sentence) == true then
    return one_sentence.dup.concat". "
  else
    return one_sentence
  end
end

def firstcap(one_sentence)
  # returns the whole sentence with the first letter only capitalized.
  # Am not using Ruby's built-in "capitalize" function since it will
  # downcase the word "I" if in the middle of a sentence
  result = one_sentence.dup
  if one_sentence.match?(/[[:lower:]]/, 0) then
    result[0] = result[0].upcase
  end
  return result
end

def a_an(one_sentence)
  # returns the sentence with a replaced with an where needed
  tempstr = one_sentence.dup
  if one_sentence.match?(/\ a\ [aieou]/) then
    tempstr.scan(/\ a\ [aeiou]/){|match|
      startmatch = tempstr.dup.index(match)
      tempstr = tempstr.dup.insert(startmatch + 2, "n")}
  end
  return tempstr
end

def edit_txts(one_sentence, characters, txtarr)
  # returns markdown-formatted text message from one sentence
  phone_action = Set["'s phone buzzed", " heard a phone notification", " pulled out a phone which had just chimed", " received an incoming message"]
  specific_phone = get_randoms(true, 1, phone_action).to_a[0]
  personid = rand(characters.size)
  if txtarr[2].include?(one_sentence) == false then
    contact = get_randoms(true, 1, characters[personid][:"familyfriends"]).to_a[0]
  else
    contact = "UNKNOWN"
  end
  result = characters[personid][:"name"].dup.concat(specific_phone, ": \n\n>", contact.upcase, " \n>\n>", one_sentence, "\n\n")
  return result
end

def edit_dialogue(one_sentence, characters)
  # returns an edited sentence from a regular sentence. This involves quotation marks and punctuation.
  said = Set["said", "remarked", "mentioned", "declared", "stated"]
  if one_sentence.include?("!") then
    final_said = "exclaimed"
  elsif one_sentence.include?("?") then
    final_said = "asked"
  else
    final_said = get_randoms(true, 1, said).to_a[0]
  end
  person = characters[rand(characters.size)][:"name"].dup
  result = firstcap(one_sentence.dup)
  beforeafter = rand(100)
  if beforeafter < 50 then
    # put stuff before
    result = person.concat(" ", final_said, ", \"", result)
    result = add_period(result).rstrip.concat("\"")
  else
    # put stuff after
    if nopunctuation(one_sentence) == true then
      closequote = ",\""
    else
      closequote = "\""
    end
    result = "\"".concat(result, closequote, " ", final_said, " ", person, ".")
  end
  return "\n\n".concat(result, "\n\n")
end

def replace_character_details(one_sentence, characters)
  # returns a sentence with all character-specific wordcodes replaced
  # with words. Sentences which are not character-specific are unaffected
  final_sentence = one_sentence.dup
  if final_sentence.match?(/_CHARACTER_/) then
    # character-specific stuff needs to be handled; pick random character
    id = rand((characters).size)
    final_sentence.gsub!("_CHARACTER_", characters[id][:"name"])
    final_sentence.gsub!("_JOB_", characters[id][:"job"])
    final_sentence.gsub!("_FAVEVERB_", characters[id][:"fave_verb"])
    final_sentence.gsub!("_HESHE_", characters[id][:"heshe"])
    final_sentence.gsub!("_HIMHER_", characters[id][:"himher"])
  end
  final_sentence
end

def replace_wordcode(one_sentence, words)
  # returns a sentence with non-character-speicific wordcodes replaced with actual words.
  # if no replacement is found for a wordcode, then "something" is used instead
  one_sentence.gsub(/_[A-Z]+_/) {|thecode|
    if words.has_key?(thecode.to_sym) then
      get_randoms(false, 1, words[thecode.to_sym]).to_a[0]
    else
      "something"
    end}
end

def iterate_section(wc_timeframe_tot)
  # the main narrative generation function. It returns the new state of the
  # returnable items (story so far, chapter, previous sentence).
  # words and sentences to be used are recalculated from their reference points
  # during each iteration and do not need to be returned.
  # The argument wc_timeframe_tot does not indicate a stopping condition, merely
  # the number of total words over which the story vocabulary needs to be mapped
  # This function is called to generate sections of the story, and
  # it's helpful to know where that section is in the context of the full work.
  lambda {|characters, base_words, base_sentences|
    recursive_bit = lambda {|desired_count, mutable_returnable, changing_words=[], changing_sentences=[]|
      wc = word_count_all(mutable_returnable[:"story-so-far"])
      if wc > desired_count then
        return mutable_returnable
      else
        new_mut = mutable_returnable
        current_word_decoder = base_words
        # word rebalancing if there are mutable words
        if changing_words.empty? == false then
          changing_words.each{|key, wordarr| current_word_decoder[key] = distribute_3_sets(wc, wordarr, wc_timeframe_tot)}
        end
        # sentence rebalancing if there are mutable sentences
        current_sentences = base_sentences
        if changing_sentences.empty? == false then
          changing_sentences.each{|key, sentencearr| current_sentences[key] = distribute_3_sets(wc, sentencearr, wc_timeframe_tot)}
        end
        newsentence = get_randoms(true, 1, current_sentences.values.to_set.flatten, Set[mutable_returnable[:"recent-sentence"]]).to_a[0]
        # before general words, enter character-specific details
        char_specific = replace_character_details(newsentence, characters)
        # next replace general words
        madlibbed = replace_wordcode(char_specific, current_word_decoder)
        # handle any additions to the sentence, necessary for diary, dialogue
        # and text messages
        if ispart(newsentence, "dialogue", changing_sentences) == true then
          madlibbed = edit_dialogue(madlibbed, characters)
        elsif ispart(newsentence, "txt", changing_sentences) == true then
          madlibbed = edit_txts(madlibbed, characters, changing_sentences[:"txt"])
        end
        madlibbed = firstcap(madlibbed.dup)
        madlibbed = add_period(madlibbed.dup)
        madlibbed = a_an(madlibbed.dup)
        new_mut[:"story-so-far"] << madlibbed
        new_mut[:"recent-sentence"] = newsentence
        recursive_bit.call(desired_count, new_mut, changing_words, changing_sentences)
      end
    }
  }
end

###########################################
########### MAIN PROGRAM ##################
###########################################
### Define important variables ###
target_totwords = 50000
min_people = 2
max_people = 6

#############
### WORDS ###
#############
file_2_wordset_lambda = file_2_set("word-data")

############## GENERAL WORDS ################
tverbs_past = file_2_wordset_lambda.call("transitive-past-tense.txt")
portablenouns = file_2_wordset_lambda.call("Portable-nouns.txt")
malenames = file_2_wordset_lambda.call("MaleNames_2019_200.txt")
femalenames = file_2_wordset_lambda.call("FemaleNames_2019_200.txt")
animal = file_2_wordset_lambda.call("Animals.txt")
tree = file_2_wordset_lambda.call("Tree-types.txt")
occupations = file_2_wordset_lambda.call("Occupations.txt")
landforms = file_2_wordset_lambda.call("Landforms.txt")
largenouns = file_2_wordset_lambda.call("Large-nouns.txt")
verbsp = file_2_wordset_lambda.call("verbs-people.txt")
see = file_2_wordset_lambda.call("see.txt")
special = file_2_wordset_lambda.call("special.txt")
examined = file_2_wordset_lambda.call("examined.txt")
walking = file_2_wordset_lambda.call("walking.txt")
nounphrases = file_2_wordset_lambda.call("mostly-noun-phrases.txt")
conj = Set["and", "but", "yet"]
sense = Set["feel", "hear", "see", "taste", "smell"]
direction = Set["forward", "onward", "south", "east", "west", "north"]
adjectives = Array.new
adjectives[0] = file_2_wordset_lambda.call("positive-adjectives.txt")
adjectives[1] = file_2_wordset_lambda.call("neutral-adjectives.txt")
adjectives[2] = file_2_wordset_lambda.call("negative-adjectives.txt")
emotions = Array.new
emotions[0] = file_2_wordset_lambda.call("positive-emotions.txt")
emotions[1] = file_2_wordset_lambda.call("neutral-emotions.txt")
emotions[2] = file_2_wordset_lambda.call("negative-emotions.txt")
adverbs = Array.new
adverbs[0] = file_2_wordset_lambda.call("positive-adverbs.txt")
adverbs[1] = file_2_wordset_lambda.call("neutral-adverbs.txt")
adverbs[2] = file_2_wordset_lambda.call("negative-adverbs.txt")
changing_words = {"_ADJ_": adjectives, "_EMOTION_": emotions, "_ADVERB_": adverbs}

######### PLOT-SPECIFIC WORDS ###########
monster_features = Set["horn", "claw", "snout", "tooth", "tail", "slime"]
monster_move = Set["slithered", "shuffled", "crept", "staggered", "shambled", "lumbered"]
monster_names = Set["Monster", "Anomaly", "Thing", "Demon", "Fiend", "Evil", "Monstrosity", "Thing", "Terror", "Loathing", "Dread", "Abhorrence", "Creature", "Malevolence"]
monster_adv = Set["malevolently", "maliciously", "calculatingly", "evilly", "basely", "horrifyingly"]
body_parts = Set["nose", "ear", "leg", "arm", "spleen", "foot", "hand", "finger", "toe", "neck", "head", "knee", "ankle", "brain", "intestine"]
city_prefixes = file_2_wordset_lambda.call("City-prefixes.txt")
city_suffixes = file_2_wordset_lambda.call("City-suffixes.txt")

#######################
#### SENTENCES ########
####################### 
file_2_sentenceset_lambda = file_2_set("sentence-data")

basic = file_2_sentenceset_lambda.call("sentences.txt")
other = file_2_sentenceset_lambda.call("other.txt")
monster_s = file_2_sentenceset_lambda.call("monster-sentences.txt")

txts = Array.new
txts[0] = file_2_sentenceset_lambda.call("positive-txts.txt")
txts[1] = file_2_sentenceset_lambda.call("neutral-txts.txt")
txts[2] = file_2_sentenceset_lambda.call("negative-txts.txt")
nonportables = Array.new
nonportables[0] = file_2_sentenceset_lambda.call("positive-lgnouns.txt")
nonportables[1] = file_2_sentenceset_lambda.call("neutral-lgnouns.txt")
nonportables[2] = file_2_sentenceset_lambda.call("negative-lgnouns.txt")
weather = Array.new
weather[0] = file_2_sentenceset_lambda.call("positive-weather.txt")
weather[1] = file_2_sentenceset_lambda.call("neutral-weather.txt")
weather[2] = file_2_sentenceset_lambda.call("negative-weather.txt")
dialogue = Array.new
dialogue[0] = file_2_sentenceset_lambda.call("positive-dialogue.txt")
dialogue[1] = file_2_sentenceset_lambda.call("neutral-dialogue.txt")
dialogue[2] = file_2_sentenceset_lambda.call("negative-dialogue.txt")
changing_sentences = {"txt": txts, "nonport": nonportables, "weather": weather, "dialogue": dialogue}

################################## 
####   start main program     #### 
##################################
# here we can assume all file data has made it in, otherwise program would
# have stopped with explanation while executing the file_2_... function

############# PROCESS SOME WORDS ###############
tree_type = tree.to_a.collect{|a| a + " tree"}.to_set
word_decoder = {"_VERBED_": tverbs_past, "_VERBING_": verbsp, "_LGNOUN_": largenouns, "_OCCUPATION_": occupations, "_SEE_": see, "_EXAMINED_": examined, "_SPECIAL_": special, "_CONJ_": conj, "_WALKING_": walking, "_DIRECTION_": direction, "_NOUNPHRASE_": nounphrases, "_SENSE_": sense}
monster_decoder = {"_MONSTERMOVE_": monster_move, "_MONSTERADV_": monster_adv, "_LGNOUN_": largenouns, "_WALKING_": walking, "_DIRECTION_": direction, "_MONSTERFEATURE_": monster_features}

plot_city_pre = select_one.call(city_prefixes).to_a[0].strip
plot_city_suf = select_one.call(city_suffixes).to_a[0].strip
city_name = plot_city_pre + plot_city_suf
monster_name = "The " + select_one.call(monster_names).to_a[0].strip
in_of = select_one.call(Set["in", "of"]).to_a[0]
title = monster_name + " " + in_of + " " + city_name

biome_tree = select_two_unique.call(tree_type)
biome_tree_plural = biome_tree.to_a.collect{|a| a + "s"}.to_set
biome_animal = select_two_unique.call(animal)
biome_animal_plural = biome_animal.to_a.collect{|a| a + "s"}.to_set
biome_landform = select_two_unique.call(landforms)
biome_landform_plural = biome_landform.to_a.collect{|a| a + "s"}.to_set
biome = biome_tree + biome_animal + biome_landform
biome_plural = biome_tree_plural + biome_animal_plural + biome_landform_plural
items_carried = select_randoms_uniques.call(3, portablenouns)

############# PROCESS SOME SENTENCES ###########
characters = Array.new
monster = Array.new
all_sentences = {"basic": basic, "other": other}
monster_sentences = {"monster": monster_s}

###### GENERATE CHARACTER SHEETS ######
number_people = (rand(min_people..max_people))
puts "Generating a story with #{number_people} characters..."
characters = generate_characters(number_people, malenames, femalenames, occupations, verbsp)

# add story-specific words to the main word list
word_decoder.store("_CITYNAME_".to_sym, Set[city_name])
word_decoder.store("_PORTABLENOUN_".to_sym, items_carried)
word_decoder.store("_BIOME_".to_sym, biome)
word_decoder.store("_BIOMEPLURAL_".to_sym, biome_plural)
monster_decoder.store("_CITYNAME_".to_sym, Set[city_name])
monster_decoder.store("_MONSTERNAME_".to_sym, Set[monster_name])
# add in the words that change in word decoder. It does not matter whether
# or not these are in place beforehand because the word rebalancer will
# handle that during story generation.
changing_words.each{|key, wordarr| word_decoder[key] = wordarr[0]}

###### GENERATE START OF STORY ############
mutable_state = {"recent-sentence": "", "chapter": 1, "story-so-far": Array.new}
start_of_story = Array.new
start_of_story << "# ".concat(title, "\n")
start_of_story << "\n## Chapter ".concat(mutable_state[:"chapter"].to_s, "\n")
start_of_story << replace_wordcode("In the distance a _BIOME_ could be seen. ", word_decoder)
character_str = arr_2_sentence(characters.collect{|person| person[:"name"]})
intro = " were _WALKING_ among the _BIOMEPLURAL_ of _CITYNAME_. For the moment, they were putting aside the strange disappearances that had been occurring. Feeling _EMOTION_, they moved _DIRECTION_, carrying with them a "
item_str = arr_2_sentence(items_carried.to_a)
full_start = character_str.dup.concat(intro, item_str, ". ")
full_start = a_an(full_start.dup)
start_of_story << replace_wordcode(full_start, word_decoder)
mutable_state[:"story-so-far"] = start_of_story

############ GENERATE THE MAIN PART OF STORY ##################
create_section_lambda = iterate_section(target_totwords)
create_section_characters_lambda = create_section_lambda.call(characters, word_decoder, all_sentences)
create_section_monster_lambda = create_section_lambda.call(characters, monster_decoder, monster_sentences)

gen_chapters = lambda{|mutable_state|
  # generate the whole story in chapters. This lambda returns the mutable state
  # of the story, which includes among other things, the story so far.
  wc = word_count_all(mutable_state[:"story-so-far"])
  if wc > target_totwords then
    mutable_state
  else
    # generate some words of regular story
    new_state = create_section_characters_lambda.call(wc + rand(500..800), mutable_state, changing_words, changing_sentences)
    # generate some words of monster stuff
    monster_decoder.store("_OCCUPATION_".to_sym, Set[select_one.call(occupations)].to_a[0])
    monster_opening_sentence = replace_wordcode("\n\n*Meanwhile, in the depths of _CITYNAME_, _MONSTERNAME_ laughed. ", monster_decoder)
    new_state[:"story-so-far"] << monster_opening_sentence
    new_state = create_section_monster_lambda.call(word_count_all(new_state[:"story-so-far"]) + 50, new_state)
    monster_closing_sentence = replace_wordcode("Soon, all that was left of the _OCCUPATION_ was a piece of ".concat(select_one.call(body_parts).to_a[0]), monster_decoder)
    new_state[:"story-so-far"] << monster_closing_sentence.concat(".*\n\n")
    # generate some more words of regular story
    new_state = create_section_characters_lambda.call(word_count_all(new_state[:"story-so-far"]) + rand(100..300), new_state, changing_words, changing_sentences)
    # new chapter
    finishedchapter = new_state[:"chapter"]
    if finishedchapter % 5 == 0 then
      puts "STATUS: Generated chapter #{finishedchapter.to_s}"
    end
    new_state[:"chapter"] = new_state[:"chapter"] + 1
    new_state[:"story-so-far"] << "\n\n## Chapter ".concat(new_state[:"chapter"].to_s, "\n\n")
    gen_chapters.call(new_state)
  end}

state = gen_chapters.call(mutable_state)
######### GENERATE END OF STORY ##########
the_ending = Array.new
the_ending[0] = "The _LGNOUN_ started advancing _MONSTERADV_ toward them, controlled by _MONSTERNAME_. They were blocked behind them by a _ADJ_ wall of _BIOMEPLURAL_ which had materialized. Suddenly they heard a rustle and caught a glimpse of a _ADJ_ _MONSTERFEATURE_. A nearby _BIOME_ snarled _ADVERB_. _MONSTERNAME_ crept near them and lunged, but missed. _CHARACTER_ swiped at it with the _PORTABLENOUN_ but this did not seem to have any effect. "
the_ending[1] = "_CHARACTER_ took out the ".concat(arr_2_sentence(items_carried), ". By repeatedly _VERBING_, they were able to combine the items together into a weapon. ")
the_ending[2] = "_CHARACTER_ threw it at _MONSTERNAME_, and it was unable to withstand its effects. Its _MONSTERFEATURE_ dulled and it became still. \n\n".concat(character_str, " walked triumphantly in the direction of home. ")
the_ending[3] = "After this, _CHARACTER_ was looking forward to going back work as a _JOB_. They all were looking forward to things being back to normal. \n\n*Behind them, a _MONSTERFEATURE_ twitched.* \n\nTHE END"
merged_decoders = word_decoder.merge(monster_decoder)
the_ending_madlibbed = the_ending.collect{|sentence|
  ch = replace_character_details(sentence, characters)
  replace_wordcode(ch, merged_decoders)}
final_story = state[:"story-so-far"] + the_ending_madlibbed

########## WRITE FINAL STORY TO FILE ##################
title_filename = title.dup.gsub(' ', '-').concat(".md")
puts "About to write to file."
if  File.exists?(title_filename) then
  print "Enter filename for story: "
  final_filename = gets.chomp
  if final_filename == "" then final_filename = title_filename end
else
  final_filename = title_filename
end
if File.exists?(final_filename) then
  abort "STOPPING: ERROR - Desired filename #{final_filename} already exists. No changes were made to it."
else
  puts "Writing #{word_count_all(final_story)} words to file: #{final_filename}"
  open(final_filename, 'w'){|out|
    final_story.each{|sentence|
      out.print(sentence)}
  }
end
