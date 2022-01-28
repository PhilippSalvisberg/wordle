create or replace package util is
   function contains(
      in_text_ct in text_ct,
      in_entry   in varchar2
   ) return boolean
      deterministic;

   function pattern(
      in_solution in varchar2,
      in_guess    in varchar2
   ) return varchar2
      deterministic;

   function encode(
      in_word        in varchar2,
      in_pattern     in varchar2,
      in_ansiconsole in integer
   ) return varchar2
      deterministic;

   function bool_to_int(in_bool in boolean) return integer
      deterministic;

   procedure add_text_ct(
      io_text_ct in out text_ct,
      in_text_ct in     text_ct
   );

   function to_csv(in_list in text_ct) return varchar2;
end util;
/
