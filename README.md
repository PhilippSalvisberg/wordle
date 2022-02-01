# Wordle Helper

## Introduction

This is an implementation of [Josh Wardle](https://github.com/powerlanguage)'s [Wordle](https://www.powerlanguage.co.uk/wordle/) in the Oracle Database using SQL and PL/SQL. This solution uses the same data. Starting with game #0 on 2021-06-19 on a daily basis. 

You can play past, current or future games. The solution is implemented with a set of table functions. The table function `wordle.play` helps guessing and visualizes the results. The table function `wordle.autoplay` plays a game automatically for you. It uses the first suggestion until it finds a solution. Sometimes it takes more than the forseen 6 guesses. It's like in real life.

I have to admit that I used [Word Finder](https://wordfinder.yourdictionary.com/) to solve the daily Wordles. I'm really bad in querying 5-letter words in my head. This web site allows to filter words by the number of letters and one or more starting and ending letters. You can use also some wildcards to formulate additional search criteria. It helped me to find fitting words for Wordle and learn the meaning of various words I never heard of.

As a database fanboy I wanted to query possible candidates via SQL, to more efficently reduce the solution space with every guess. And I've seen that [Filipe Hoffa](https://twitter.com/felipehoffa/status/1482148680798904321) and [Connor McDonald](https://twitter.com/connor_mc_d/status/1484076351087058946) not only tweeted about Wordle, but also made some progress with their database driven Wordle approaches. So, I decided to give it a try.

## Prerequisites

* Oracle Datbase 19c or higher
* Oracle SQLcl for ANSI console output variant
* Any SQL client should be fine for the ASCII output variant

## Installation

1. Create a user in the Oracle Database. See [create_user.sql](main/user/create_user.sql) for an example.

2. Clone or download this GitHub repsitory.

3. Open a terminal window and change to the directory containing this README.md file

    ```
    cd (...)
    ```

4. Connect to the database and execute this script (I've used it sucessfully with SQLcl und SQL Developer):

    ```sql
    @install.sql
    ```  

## Model

The installation scripts creates and populates this database model:

![Data Model](model/data-model.png)

The main table is `WORDS`. It contains `12972` accepted words. `2315` of these words are used as solutions. They have an assosciated `GAME_ID` and `GAME_DATE`. As a result they are used only once. The last Wordle game #2314 is scheduled for 2027-10-20.

## Semantic

## ANSI Console

![ANSI Console](image/wordle-play-ansi.png)

To do this, you must use `set linesize 250` (or higher) because the ANSI escape sequences inflate the result column. If you reduce the line size the result may be wrapped or truncated depending on your settings.

The colors are similar to those used in Wordle. They should therefore be self-explanatory.

## ASCII (Plain)

![ANSI Console](image/wordle-play-ascii.png)

This works in any SQL client and is therefore the default. The next table should make the semantic clear.

ASCII | ANSI | Notes / Mnemonics
-- | -- | --
.T. | <img src="image/t-green-box.svg" alt="T" width="20">| Dots mean the letter is at the right position. The dots are like anchors on both sides, making the result final.
(N) | <img src="image/n-gold-box.svg" alt="N" width="20"> | Parenthesis mean the right letter but at the wrong position. 
-U- | <img src="image/u-gray-box.svg" alt="U" width="20"> | Dashes mean the letter is not used (also when there are too many occurrences of a letter). It's similar to the syntax used  in some Wikis to cross out words.


## Single Guess via Table Function `wordle.play`

### Example

The idea is to call this function per guess. The following call:

```sql
set pagesize 1000
set linesize 100
select * from wordle.play(209, 'noise');
```

produces this result:

```
Result Sequence 
----------------------------------------------------------------------------------------------------
(N) -O- -I- -S- -E-

with
   other_letters as (
      select w.word
        from words w
        join letter_in_words lw
          on lw.word = w.word
        join letters l
          on l.letter = lw.letter
       where lw.letter not in ('n', 'o', 'i', 's', 'e')
       group by w.word
      having count(*) >= 4
       order by count(*) desc, sum(l.is_vowel), sum(l.occurrences) desc, w.word
       fetch first 1 row only
   ),
   hard_mode as (
      select word
        from words
       where word like '_____'
         and word not like 'n____'
         and instr(word, 'n', 1, 1) > 0
         and word not like '%o%'
         and word not like '%i%'
         and word not like '%s%'
         and word not like '%e%'
         and word not in ('noise')
       order by case when game_id is not null then 0 else 1 end, word
       fetch first 10 rows only
   ),
   all_matcher as (
      select word
        from other_letters 
      union all 
      select word
        from hard_mode
   )
select word 
  from all_matcher
 fetch first 10 rows only

crypt
angry
annul
aunty
banal
bland
blank
blunt
brand
brawn

13 rows selected. 
```

In the first part the guess is evaluated. `(N) -O- -I- -S- -E-` is shown.

In the second part the guesses are used to produce a query for suggestions. In this example a query in normal mode is shown. That's the default. You can call `exec wordle.set_hard_mode(true);` to enforce reusing known letters.

In the third part some suggestions are shown. `10` is the default. You may change that by calling `exec wordle.set_suggestions(...);`. Another option is to copy und paste the query and run it with adapted limits.

You can call `exec wordle.set_show_query(false);` to suppress the display of the suggestions query.

### Signatures

Here are the relevant signaturs of the PL/SQL package `wordle` for the `play` functions.

```sql
function play(
  in_game_id  in integer,
  in_words    in text_ct,
  in_autoplay in integer default 0
) return text_ct;

function play(
  in_game_id in integer,
  in_word1   in varchar2,
  in_word2   in varchar2 default null,
  in_word3   in varchar2 default null,
  in_word4   in varchar2 default null,
  in_word5   in varchar2 default null,
  in_word6   in varchar2 default null
) return text_ct;

function play(
  in_word1 in varchar2,
  in_word2 in varchar2 default null,
  in_word3 in varchar2 default null,
  in_word4 in varchar2 default null,
  in_word5 in varchar2 default null,
  in_word6 in varchar2 default null
) return text_ct;
```

`text_ct` is a collection type which is defined as `table of varchar2(4000 byte)`. The second and third signature are provided for convenience.

If you do not pass a `in_game_id` then the game id is determined according the current date (`sysdate`).

## Autonomous Guesses via Table Function `wordle.autoplay`

### Example

The idea is to set a starting point and let the machine do the guessing. The following call:

```sql
set pagesize 1000
set linesize 100
select * from wordle.autoplay(209);
```

produces this result:

```
Result Sequence 
----------------------------------------------------------------------------------------------------

with
   other_letters as (
      select w.word
        from words w
        join letter_in_words lw
          on lw.word = w.word
        join letters l
          on l.letter = lw.letter
       group by w.word
      having count(*) >= 4
       order by count(*) desc, sum(l.is_vowel), sum(l.occurrences) desc, w.word
       fetch first 1 row only
   ),
   hard_mode as (
      select word
        from words
       where word like '_____'
       order by case when game_id is not null then 0 else 1 end, word
       fetch first 10 rows only
   ),
   all_matcher as (
      select word
        from other_letters 
      union all 
      select word
        from hard_mode
   )
select word 
  from all_matcher
 fetch first 10 rows only

rynds
aback
abase
abate
abbey
abbot
abhor
abide
abled
abode

autoplay added: rynds (1)

-R- (Y) .N. -D- -S-

with
   other_letters as (
      select w.word
        from words w
        join letter_in_words lw
          on lw.word = w.word
        join letters l
          on l.letter = lw.letter
       where lw.letter not in ('y', 'n', 'r', 'd', 's')
       group by w.word
      having count(*) >= 4
       order by count(*) desc, sum(l.is_vowel), sum(l.occurrences) desc, w.word
       fetch first 1 row only
   ),
   hard_mode as (
      select word
        from words
       where word like '__n__'
         and word not like '_y___'
         and instr(word, 'y', 1, 1) > 0
         and instr(word, 'n', 1, 1) > 0
         and word not like '%r%'
         and word not like '%d%'
         and word not like '%s%'
         and word not in ('rynds')
       order by case when game_id is not null then 0 else 1 end, word
       fetch first 10 rows only
   ),
   all_matcher as (
      select word
        from other_letters 
      union all 
      select word
        from hard_mode
   )
select word 
  from all_matcher
 fetch first 10 rows only

clept
annoy
aunty
boney
bunny
canny
fancy
fanny
funky
funny

autoplay added: clept (2)

-R- (Y) .N. -D- -S-
-C- -L- -E- -P- (T)

with
   other_letters as (
      select w.word
        from words w
        join letter_in_words lw
          on lw.word = w.word
        join letters l
          on l.letter = lw.letter
       where lw.letter not in ('y', 'n', 't', 'r', 'd', 's', 'c', 'l', 'e', 'p')
       group by w.word
      having count(*) >= 4
       order by count(*) desc, sum(l.is_vowel), sum(l.occurrences) desc, w.word
       fetch first 1 row only
   ),
   hard_mode as (
      select word
        from words
       where word like '__n__'
         and word not like '_y___'
         and word not like '____t'
         and instr(word, 'y', 1, 1) > 0
         and instr(word, 'n', 1, 1) > 0
         and instr(word, 't', 1, 1) > 0
         and word not like '%r%'
         and word not like '%d%'
         and word not like '%s%'
         and word not like '%c%'
         and word not like '%l%'
         and word not like '%e%'
         and word not like '%p%'
         and word not in ('rynds', 'clept')
       order by case when game_id is not null then 0 else 1 end, word
       fetch first 10 rows only
   ),
   all_matcher as (
      select word
        from other_letters 
      union all 
      select word
        from hard_mode
   )
select word 
  from all_matcher
 fetch first 10 rows only

ogham
aunty
minty
tangy
banty
bunty
janty
jonty
manty
monty

autoplay added: ogham (3)

-R- (Y) .N. -D- -S-
-C- -L- -E- -P- (T)
-O- (G) -H- (A) -M-

with
   hard_mode as (
      select word
        from words
       where word like '__n__'
         and word not like '_y___'
         and word not like '____t'
         and word not like '_g___'
         and word not like '___a_'
         and instr(word, 'y', 1, 1) > 0
         and instr(word, 'n', 1, 1) > 0
         and instr(word, 't', 1, 1) > 0
         and instr(word, 'g', 1, 1) > 0
         and instr(word, 'a', 1, 1) > 0
         and word not like '%r%'
         and word not like '%d%'
         and word not like '%s%'
         and word not like '%c%'
         and word not like '%l%'
         and word not like '%e%'
         and word not like '%p%'
         and word not like '%o%'
         and word not like '%h%'
         and word not like '%m%'
         and word not in ('rynds', 'clept', 'ogham')
       order by case when game_id is not null then 0 else 1 end, word
   )
select word 
  from hard_mode
 fetch first 10 rows only

tangy

autoplay added: tangy (4)

-R- (Y) .N. -D- -S-
-C- -L- -E- -P- (T)
-O- (G) -H- (A) -M-
.T. .A. .N. .G. .Y.

Bravo! You completed Wordle 209 4/6

63 rows selected. 
```

In this case no guess was used as starting point. This works. `autoplay` always chooses the first suggestion, also for the very first guess. This process is repeated until a solution is found. It does not matter how many guesses are necessary. In 99.96 percent of the cases a solution is found within 6 guesses in normal mode (95.51 percent in hard mode).

### Signatures

Here are the relevant signaturs of the PL/SQL package `wordle` for the `autoplay` functions.

```sql
function play(
  in_game_id  in integer,
  in_words    in text_ct,
  in_autoplay in integer default 0
) return text_ct;

function autoplay(
  in_game_id in integer,
  in_word1   in varchar2 default null,
  in_word2   in varchar2 default null,
  in_word3   in varchar2 default null,
  in_word4   in varchar2 default null,
  in_word5   in varchar2 default null,
  in_word6   in varchar2 default null
) return text_ct;

function autoplay(
  in_word1 in varchar2 default null,
  in_word2 in varchar2 default null,
  in_word3 in varchar2 default null,
  in_word4 in varchar2 default null,
  in_word5 in varchar2 default null,
  in_word6 in varchar2 default null
) return text_ct;
```

The functions are basically identical to the other `play` functions. The only difference is that the `in_autoplay` parameter is set to `1` (true).
