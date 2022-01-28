create or replace type guess_ot force as object (
   word    varchar2(5 char),
   pattern varchar2(5 char),
   errors  text_ct,
   constructor function guess_ot(
      self              in out nocopy guess_ot,
      in_word           in            varchar2,
      in_solution       in            varchar2,
      in_previous_guess in            guess_ot,
      in_hard_mode      in            integer
   ) return self as result,
   member function is_valid return integer,
   member function containing_letters return text_ct,
   member function missing_letters(in_solution in varchar2) return text_ct,
   member function like_pattern return varchar2,
   member function not_like_patterns return text_ct
);
/
