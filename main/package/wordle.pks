create or replace package wordle is
   procedure set_ansiconsole(in_ansiconsole boolean default true);

   procedure set_suggestions(in_suggestions integer default 10);

   procedure set_show_query(in_show_query boolean default true);

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
   
end wordle;
/