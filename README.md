# Horror Story with Monster NaNoGenMo 2020
Generates a work of fiction of > 50,000 words. The story generated is in the horror genre. 

The novel is generated via madlib-style word substitutions into sentences. I made up the various madlib sentences myself; the words come from word lists whose origins are listed in the credits below.

The user is not prompted for anything except for the output filename if a file with the default name already exists.

## Features
- A random number of main characters are generated each time the program is run. This numerical range is currently set from 2 to 6, but can easily be altered by changing the corresponding 2 variables.

- A specific biome is assigned to the story each time the program is run, so different runs of the program should result in different biomes. A biome is defined here as 2 types of animals, 2 types of trees, and 2 types of landforms. There are frequent references made to the biome during the novel, hopefully giving a sense of environment

- Text messages. Characters receive text messages during the course of the novel.

- Character-specific things: each character has a favorite verb which they frequently do during the course of the story, they have their own contact lists from whom they receive text messages, and they have an occupation.

- Defined end point to the story.

- Monster interludes. Somewhere during each chapter, a monster attacks and kills an unsuspecting minor character. 

- The next sentence type is different to the sentence before it.

- Some (but not all) types of words change over the course of the story, as do some of the sentences. For example, at the start of the story, the adjectives are all positive e.g. "serene", "beautiful", etc. In the middle, they are neutral e.g. "unobjectionable", "uninspired". At the end, they are negative e.g. "malign", "disquieting". The distribution of positive and negative words available at any time is a mix that is dependent on how far through the story we are at that time. This distribution is recalculated each iteration. Other things which change over the course of the story are the text messages, weather descriptions, and adverbs. Thus, the story vocabulary in general becomes more hostile over time.

- The algorithm is able to handle separate vocabulary sets for separate sections. In this story I utilized a different set of vocabulary for the monster interludes (which contained monster-specific words and sentences that did not change over time) compared to the vocabulary used in the main part of the story. 

## Usage
Simply copy the files to your working directory. You should now have the file `horror.rb` and the folders `word-data` and `sentence-data` there. The `example-output` folder is not necessary. Assuming you have Ruby installed in your system, in the command line in Linux (or on a Windows command prompt) in your working directory, type:

`ruby horror.rb` 

The algorithm will generate a horror story of > 50,000 words and write it to a file in Markdown format.

## Technical information
There are no special or unusual things required for this algorithm to work.

This algorithm was developed and tested using Ruby v 2.7.0 in a Linux environment. There are no keyword parameters used in the functions of this program, therefore it is expected to be compatible with the upcoming Ruby 3.0 release. Some functions have optional parameters, in case that is of future relevance.

This algorithm was additionally tested and runs successfully on Ruby 2.7.2-1-no-devkit on a Windows 10 environment using the Ruby Installer for Windows from [rubyinstaller.org](rubyinstaller.org).

This algorithm remains untested on Apple OS.

### Credits:
#### Words came from the following sources
1. The public domain book at Project Gutenberg: [Part-of-Speech II by Grady Ward 2002](http://www.gutenberg.org/ebooks/3203). For details about how I parsed those words for use, see [https://github.com/verachell/English-word-lists-parts-of-speech-approximate](https://github.com/verachell/English-word-lists-parts-of-speech-approximate)

2. The [SCOWL/Aspell package](http://wordlist.aspell.net/) which was provided in the Linux distro I use at `/usr/share/dict`

3. Male and female names came from the list of most popular baby names in the US for the year 2019 at https://[www.ssa.gov/OACT/babynames/index.html](https://www.ssa.gov/OACT/babynames/index.html). The 200 most popular names for male and for female names were used in this project.
 
4. Word lists I created manually at [https://github.com/verachell/English-word-lists-miscellaneous-categories](https://github.com/verachell/English-word-lists-miscellaneous-categories), and a few other word lists I created manually specifically for this story.
