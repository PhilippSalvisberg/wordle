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
      for i in 1..in_text_ct.count
      loop
         if in_text_ct(i) = in_entry then
            return true;
         end if;
      end loop entries;
      return false;
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
      type t_letter_type is table of pls_integer index by varchar2(1);
      t_solution_letters t_letter_type := t_letter_type();
      t_guess_letters    t_letter_type := t_letter_type();
      l_pattern          varchar2(5);
      l_solution_letter  varchar2(1);
      l_guess_letter     varchar2(1);
      --
      procedure add_letter(
         io_letters in out t_letter_type,
         in_letter  in     varchar2
      ) is
      begin
         if io_letters.exists(in_letter) then
            io_letters(in_letter) := io_letters(in_letter) + 1;
         else
            io_letters(in_letter) := 1;
         end if;
      end add_letter;
      --
      procedure append(in_match in varchar2) is
      begin
         l_pattern := l_pattern || in_match;
      end append;
      --
      function number_of_guessed_letter(
         in_solution in varchar2,
         in_guess    in varchar2,
         in_letter   in varchar2
      ) return integer is
         l_result integer := 0;
      begin
         <<letters>>
         for i in 1..length(in_solution)
         loop
            if substr(in_solution, i, 1) = in_letter and substr(in_guess, i, 1) = in_letter then
               l_result := l_result + 1;
            end if;
         end loop letters;
         return l_result;
      end number_of_guessed_letter;
   begin
      <<letters>>
      for i in 1..length(in_solution)
      loop
         add_letter(t_solution_letters, substr(in_solution, i, 1));
      end loop letters;

      <<letters>>
      for i in 1..length(in_solution)
      loop
         l_solution_letter := substr(in_solution, i, 1);
         l_guess_letter    := substr(in_guess, i, 1);
         add_letter(t_guess_letters, l_guess_letter);
         if l_guess_letter = l_solution_letter then
            append('2');
         elsif instr(in_solution, l_guess_letter) > 0
            and (t_solution_letters(l_guess_letter)
               - number_of_guessed_letter(in_solution, in_guess, l_guess_letter)
               - t_guess_letters(l_guess_letter) >= 0)
         then
            append('1');
         else
            append('0');
         end if;
      end loop letters;
      return l_pattern;
   end pattern;

   -- -----------------------------------------------------------------------------------------------------------------
   -- add_text_ct
   -- -----------------------------------------------------------------------------------------------------------------
   procedure add_text_ct(
      io_text_ct in out text_ct,
      in_text_ct in     text_ct
   ) is
   begin
      for i in 1..in_text_ct.count
      loop
         if not contains(io_text_ct, in_text_ct(i)) then
            io_text_ct.extend;
            io_text_ct(io_text_ct.count) := in_text_ct(i);
         end if;
      end loop;
   end add_text_ct;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- to_csv
   -- -----------------------------------------------------------------------------------------------------------------
   function to_csv(in_list in text_ct) return varchar2 is
      l_list varchar2(4000 byte);
   begin
      <<entries>>
      for i in 1..in_list.count
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
