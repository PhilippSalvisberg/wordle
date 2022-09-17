create or replace package common is
   -- The length of the column word in tables word and letter_in_words.
   -- Constant cannot be used in tables and object type definitions.
   co_word_len constant integer := 5;

   -- The maximum number of guesses allowed in the official game.
   -- This wordle helper supports an unlimited number of guesses.
   co_max_guesses constant integer := 6;
end common;
/
