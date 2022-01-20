-- --------------------------------------------------------------------------------------------------------------------
-- Wordle solutions
-- --------------------------------------------------------------------------------------------------------------------

select * from words order by game_on desc nulls last;
select * from words where game_number between 208 and 215;

-- --------------------------------------------------------------------------------------------------------------------
-- occurrencies of vowels in present and future Worlde solutions
-- --------------------------------------------------------------------------------------------------------------------
 
select character, sum(occurrences) as occurrences
  from char_in_words
natural join chars
natural join words
 where is_vowel = 1
   and game_on >= sysdate
 group by character
 order by occurrences desc;
 