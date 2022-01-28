create or replace type game_ot force as object (
   solution  varchar2(5 char),
   hard_mode integer,
   guesses   guess_ct,
   constructor function game_ot(
      self         in out nocopy game_ot,
      in_solution  in            varchar2,
      in_hard_mode in            integer,
      in_guesses   in            text_ct
   ) return self as result,
   member function is_initialized return integer,
   member function is_completed return integer,
   member function errors return text_ct,
   member procedure add_guess(in_word in varchar2),
   member function valid_guesses return guess_ct,
   member function containing_letters return text_ct,
   member function missing_letters return text_ct,
   member function like_pattern return varchar2,
   member function not_like_patterns return text_ct,
   member function suggestions_query(in_rows in integer default 10) return varchar2,
   member function suggestions(in_rows in integer default 10) return text_ct
);
/
