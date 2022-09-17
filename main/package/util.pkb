create or replace package body util is
   -- -----------------------------------------------------------------------------------------------------------------
   -- contains
   -- -----------------------------------------------------------------------------------------------------------------
   function contains(
      in_text_ct in text_ct,
      in_entry   in varchar2
   ) return boolean
      deterministic
   is
   begin
      <<entries>>
      for i in 1..in_text_ct.count -- NOSONAR: plsql:ForLoopUsageCheck dense array
      loop
         if in_text_ct(i) = in_entry then
            return true; -- NOSONAR G-7430: return a.s.a.p
         end if;
      end loop entries;
      return false; -- NOSONAR G-7430
   end contains;

   -- -----------------------------------------------------------------------------------------------------------------
   -- pattern
   -- -----------------------------------------------------------------------------------------------------------------
   function pattern(
      in_solution in varchar2,
      in_guess    in varchar2
   ) return varchar2
      deterministic
   is
      type t_letter_type is table of pls_integer index by varchar2(1 char);
      t_solution_letters         t_letter_type := t_letter_type();
      t_rightpos_letters         t_letter_type := t_letter_type();
      t_running_wrongpos_letters t_letter_type := t_letter_type();
      l_pattern                  varchar2(5 char);
      l_solution_letter          varchar2(1 char);
      l_guess_letter             varchar2(1 char);
      --
      procedure add_letter(
         io_letters             in out t_letter_type,
         in_letter              in     varchar2,
         in_increment_condition in     boolean
      ) is
         l_increment binary_integer := 0; -- NOSONAR: G-2410: no dual meaning (false positive)
      begin
         if in_increment_condition then
            l_increment := 1;
         end if;
         if io_letters.exists(in_letter) then
            io_letters(in_letter) := io_letters(in_letter) + l_increment;
         else
            io_letters(in_letter) := l_increment;
         end if;
      end add_letter;
      --
      procedure append(in_match in varchar2) is
      begin
         l_pattern := l_pattern || in_match;
      end append;
   begin
      <<letters>>
      for i in 1..length(in_solution)
      loop
         l_solution_letter := substr(in_solution, i, 1);
         l_guess_letter    := substr(in_guess, i, 1);
         add_letter(t_solution_letters, l_solution_letter, true);
         add_letter(t_rightpos_letters, l_guess_letter, l_solution_letter = l_guess_letter);
      end loop letters;

      <<letters>>
      for i in 1..length(in_solution)
      loop
         l_solution_letter := substr(in_solution, i, 1);
         l_guess_letter    := substr(in_guess, i, 1);
         add_letter(t_running_wrongpos_letters, l_guess_letter,
                    instr(in_solution, l_guess_letter) > 0 and l_solution_letter != l_guess_letter);
         if l_guess_letter = l_solution_letter then
            append('2');
         elsif instr(in_solution, l_guess_letter) > 0
            and (t_solution_letters(l_guess_letter)
               - t_running_wrongpos_letters(l_guess_letter)
               - t_rightpos_letters(l_guess_letter) >= 0)
         then
            append('1');
         else
            append('0');
         end if;
      end loop letters;
      return l_pattern;
   end pattern;

   -- -----------------------------------------------------------------------------------------------------------------
   -- encode
   -- -----------------------------------------------------------------------------------------------------------------
   function encode(
      in_word        in varchar2,
      in_pattern     in varchar2,
      in_ansiconsole in integer
   ) return varchar2
      deterministic
   is
      -- ANSI console escape sequences, defined with RGB values
      -- see also https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
      co_fg       constant varchar2(30 char) := chr(27) || '[38;2;255;255;255m';
      co_bg_green constant varchar2(30 char) := chr(27) || '[48;2;104;171;63m';
      co_bg_gold  constant varchar2(30 char) := chr(27) || '[48;2;198;181;94m';
      co_bg_gray  constant varchar2(30 char) := chr(27) || '[48;2;120;124;126m';
      co_reset    constant varchar2(30 char) := chr(27) || '[0m';
      --
      l_result    varchar2(1000 char);
      --
      procedure append(in_value in varchar2) is
      begin
         l_result := l_result || in_value;
      end append;
      -- 
      procedure append_letter(
         in_letter in varchar2,
         in_match  in varchar2
      ) is
      begin
         if in_ansiconsole = 1 then
            append(co_fg);
            case in_match
               when '2' then
                  append(co_bg_green);
               when '1' then
                  append(co_bg_gold);
               else
                  append(co_bg_gray);
            end case;
            append(' ');
            append(in_letter);
            append(' ');
            append(co_reset);
         else
            case in_match
               when '2' then
                  append('.');
                  append(in_letter);
                  append('.');
               when '1' then
                  append('(');
                  append(in_letter);
                  append(')');
               else
                  append('-');
                  append(in_letter);
                  append('-');
            end case;
         end if;
      end append_letter;
   begin
      <<process_pattern_positions>>
      for i in 1..length(in_word)
      loop
         append_letter(upper(substr(in_word, i, 1)), substr(in_pattern, i, 1));
         if i < 5 then
            append(' '); -- character separator
         end if;
      end loop process_pattern_positions;
      return l_result;
   end encode;

   -- -----------------------------------------------------------------------------------------------------------------
   -- bool_to_int
   -- -----------------------------------------------------------------------------------------------------------------
   function bool_to_int(in_bool in boolean) return integer
      deterministic
   is
   begin
      return (case
                 when in_bool then
                    1
                 else
                    0
              end);
   end bool_to_int;

   -- -----------------------------------------------------------------------------------------------------------------
   -- add_text_ct
   -- -----------------------------------------------------------------------------------------------------------------
   procedure add_text_ct(
      io_text_ct in out text_ct,
      in_text_ct in     text_ct
   ) is
   begin
      <<entries>>
      for i in 1..in_text_ct.count -- NOSONAR: plsql:ForLoopUsageCheck dense array
      loop
         if not contains(io_text_ct, in_text_ct(i)) then
            io_text_ct.extend;
            io_text_ct(io_text_ct.count) := in_text_ct(i);
         end if;
      end loop entries;
   end add_text_ct;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- to_csv
   -- -----------------------------------------------------------------------------------------------------------------
   function to_csv(in_list in text_ct) return varchar2 is
      l_list varchar2(4000 byte);
   begin
      <<entries>>
      for i in 1..in_list.count -- NOSONAR: plsql:ForLoopUsageCheck dense array
      loop
         if l_list is not null then
            l_list := l_list || ', ';
         end if;
         l_list := l_list
                   || ''''
                   || in_list(i)
                   || '''';
      end loop entries;
      return l_list;
   end to_csv;
end util;
/
