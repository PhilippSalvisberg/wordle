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

1. Create a user in the Oracle Database. No special rights. `connect` and `resource` is enough. I named the user `wordle`. But you can choose whatever you want.

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

The only table used for Wordle is `WORDS`. It contains `12972` accepted words. `2315` of these words are used as solutions. They have an assosciated `GAME_NUMBER` and `GAME_ON` date. As a result they are used only once. The last Wordle game #2314 is scheduled for 2027-10-20.


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
.T. | <span style="background-color:#68AB67;color:#ffffff;">&nbsp;T&nbsp;</span> | Dots mean the letter is at the right position. The dots are like anchors on both sides, making the result final.
(N) | <span style="background-color:#C6B55E;color:#ffffff;">&nbsp;N&nbsp;</span> | Parenthesis mean the right letter but at the wrong position. 
-U- | <span style="background-color:#787C7E;color:#ffffff;">&nbsp;U&nbsp;</span> | Dashes mean the letter is not used (multiple occurrences of the same letter are not honored). It's similar to the syntax used  in some Wikis to cross out words.


## Single Guess via Table Function `wordle.play`

### Example

The idea is to call this function per guess. The following call:

```sql
select * from wordle.play(209, 'noise');
```

produces this result:

```
Result Sequence                                                                                     
----------------------------------------------------------------------------------------------------
(N) -O- -I- -S- -E-

select word
  from words
 where word like '_____'
   and word like '%n%'
   and word not like '%e%'
   and word not like '%i%'
   and word not like '%o%'
   and word not like '%s%'
   and word not in ('noise')
 order by case when game_number is not null then 0 else 1 end, word
 fetch first 10 rows only

angry
annul
aunty
banal
bland
blank
blunt
brand
brawn
brunt

12 rows selected. 
```

In the first part the guess is evaluated. `(N) -O- -I- -S- -E-` is shown.

In the second part the guesses are used to produce a query for suggestions. For a single guess the query is quite simple. 

In the third part some suggestions are shown. `10` is the default. You may change that by calling `exec wordle.set_suggestions(...);`. Another option is to copy und paste the query and run it.

### Signatures

Here are the relevant signaturs of the PL/SQL package `wordle` for the `play` functions.

```sql
   function play(
      in_game_number in words.game_number%type,
      in_words       in word_ct,
      in_autoplay    in integer default 0
   ) return word_ct;

   function play(
      in_game_number in words.game_number%type,
      in_word1       in words.word%type,
      in_word2       in words.word%type default null,
      in_word3       in words.word%type default null,
      in_word4       in words.word%type default null,
      in_word5       in words.word%type default null,
      in_word6       in words.word%type default null
   ) return word_ct;
   
   function play(
      in_word1 in words.word%type,
      in_word2 in words.word%type default null,
      in_word3 in words.word%type default null,
      in_word4 in words.word%type default null,
      in_word5 in words.word%type default null,
      in_word6 in words.word%type default null
   ) return word_ct;
```

`word_ct` is a collection type which is defined as `table of varchar2(1000 char)`. The second and third signature are provided for convenience.

If you do not pass a `in_game_number` then the game number is determined according the ccurrent date (`sysdate`).

## Autonomous Guesses via Table Function `wordle.autoplay`

### Example

The idea is to set a starting point and let the machine do the guessing. The following call:

```sql
select * from wordle.autoplay(209);
```

produces this result:

```

Result Sequence                                                                                     
----------------------------------------------------------------------------------------------------

select word
  from words
 where word like '_____'
 order by case when game_number is not null then 0 else 1 end, word
 fetch first 10 rows only

aback
abase
abate
abbey
abbot
abhor
abide
abled
abode
abort

autoplay added: aback (1)

(A) -B- -A- -C- -K-

select word
  from words
 where word like '_____'
   and word like '%a%'
   and word not like '%b%'
   and word not like '%c%'
   and word not like '%k%'
   and word not in ('aback')
 order by case when game_number is not null then 0 else 1 end, word
 fetch first 10 rows only

adage
adapt
adept
admin
admit
adopt
adore
adorn
adult
affix

autoplay added: adage (2)

(A) -B- -A- -C- -K-
(A) -D- -A- .G. -E-

select word
  from words
 where word like '___g_'
   and word like '%a%'
   and word not like '%b%'
   and word not like '%c%'
   and word not like '%d%'
   and word not like '%e%'
   and word not like '%k%'
   and word not in ('aback', 'adage')
 order by case when game_number is not null then 0 else 1 end, word
 fetch first 10 rows only

align
laugh
manga
mango
mangy
tango
tangy
tonga
aargh
ahigh

autoplay added: align (3)

(A) -B- -A- -C- -K-
(A) -D- -A- .G. -E-
(A) -L- -I- .G. (N)

select word
  from words
 where word like '___g_'
   and word like '%a%'
   and word like '%n%'
   and word not like '%b%'
   and word not like '%c%'
   and word not like '%d%'
   and word not like '%e%'
   and word not like '%i%'
   and word not like '%k%'
   and word not like '%l%'
   and word not in ('aback', 'adage', 'align')
 order by case when game_number is not null then 0 else 1 end, word
 fetch first 10 rows only

manga
mango
mangy
tango
tangy
tonga
fanga
fango
fangs
gangs

autoplay added: manga (4)

(A) -B- -A- -C- -K-
(A) -D- -A- .G. -E-
(A) -L- -I- .G. (N)
-M- .A. .N. .G. -A-

select word
  from words
 where word like '_ang_'
   and word like '%a%'
   and word like '%n%'
   and word not like '%b%'
   and word not like '%c%'
   and word not like '%d%'
   and word not like '%e%'
   and word not like '%i%'
   and word not like '%k%'
   and word not like '%l%'
   and word not like '%m%'
   and word not in ('aback', 'adage', 'align', 'manga')
 order by case when game_number is not null then 0 else 1 end, word
 fetch first 10 rows only

tango
tangy
fanga
fango
fangs
gangs
hangs
panga
pangs
ranga

autoplay added: tango (5)

(A) -B- -A- -C- -K-
(A) -D- -A- .G. -E-
(A) -L- -I- .G. (N)
-M- .A. .N. .G. -A-
.T. .A. .N. .G. -O-

select word
  from words
 where word like 'tang_'
   and word like '%a%'
   and word like '%n%'
   and word not like '%b%'
   and word not like '%c%'
   and word not like '%d%'
   and word not like '%e%'
   and word not like '%i%'
   and word not like '%k%'
   and word not like '%l%'
   and word not like '%m%'
   and word not like '%o%'
   and word not in ('aback', 'adage', 'align', 'manga', 'tango')
 order by case when game_number is not null then 0 else 1 end, word
 fetch first 10 rows only

tangy
tanga
tangs

autoplay added: tangy (6)

(A) -B- -A- -C- -K-
(A) -D- -A- .G. -E-
(A) -L- -I- .G. (N)
-M- .A. .N. .G. -A-
.T. .A. .N. .G. -O-
.T. .A. .N. .G. .Y.

Bravo! You completed Wordle 209 6/6

100 rows selected. 
```

In this case no guess was used as starting point. This works. `autoplay` always chooses the first suggestion, also for the very first guess. This process is repeated until a solution is found. It does not matter how many guesses are necessary. Currently in a bit more than 80% of the cases a solution is found within 6 guesses. In one case 12 guesses are necessary. This could and should be improved.

### Signatures

Here are the relevant signaturs of the PL/SQL package `wordle` for the `autoplay` functions.

```sql
   function play(
      in_game_number in words.game_number%type,
      in_words       in word_ct,
      in_autoplay    in integer default 0
   ) return word_ct;

   function autoplay(
      in_game_number in words.game_number%type,
      in_word1       in words.word%type default null,
      in_word2       in words.word%type default null,
      in_word3       in words.word%type default null,
      in_word4       in words.word%type default null,
      in_word5       in words.word%type default null,
      in_word6       in words.word%type default null
   ) return word_ct;

   function autoplay(
      in_word1       in words.word%type default null,
      in_word2       in words.word%type default null,
      in_word3       in words.word%type default null,
      in_word4       in words.word%type default null,
      in_word5       in words.word%type default null,
      in_word6       in words.word%type default null
   ) return word_ct;
```

The functions are basically identical to the other `play` functions. The only difference is that the `in_autoplay` parameter is set to `1` (true).
