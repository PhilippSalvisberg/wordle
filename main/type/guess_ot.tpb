create or replace type body guess_ot as
   -- -----------------------------------------------------------------------------------------------------------------
   -- guess_ot (constructor)
   -- -----------------------------------------------------------------------------------------------------------------
   constructor function guess_ot(
      self              in out nocopy guess_ot, -- NOSONAR G-7150: cannot remove self, false positive
      in_word           in            varchar2,
      in_solution       in            varchar2,
      in_previous_guess in            guess_ot,
      in_hard_mode      in            integer
   ) return self as result is
      procedure add_error(in_text in varchar2) is
      begin
         errors.extend;
         errors(errors.count) := in_text;
      end add_error;
      --
      function number_of_letters_in_guess(
         in_letter in varchar2
      ) return integer is
         i_count integer := 0;
      begin
         <<letters>>
         for i in 1..5
         loop
            if substr(in_previous_guess.word, i, 1) = in_letter then
               if substr(in_previous_guess.pattern, i, 1) in ('2', '1') then
                  i_count := i_count + 1;
               end if;
            end if;
         end loop letters;
         return i_count;
      end number_of_letters_in_guess;
      --
      procedure check_hard_mode is
         l_match  varchar2(1);
         l_letter varchar2(1);
      begin
         <<letters>>
         for i in 1..5
         loop
            l_match  := substr(in_previous_guess.pattern, i, 1);
            l_letter := substr(in_previous_guess.word, i, 1);
            if l_match = 2 and l_letter != substr(word, i, 1) then
               add_error(word
                  || '''s letter #'
                  || i
                  || ' is not a '
                  || upper(l_letter)
                  || '.');
            elsif l_match = 1 and regexp_count(word, l_letter) < number_of_letters_in_guess(l_letter) then
               add_error(word
                  || ' does not contain letter '
                  || upper(l_letter)
                  || ' ('
                  || regexp_count(in_previous_guess.word, l_letter)
                  || ' times).');
            end if;
         end loop letters;
      end check_hard_mode;
      --
      function exists_word(in_word in varchar2) return boolean is
         l_count integer;
      begin
         select count(*)
           into l_count
           from words
          where word = in_word
            and rownum = 1;
         return l_count > 0;
      end exists_word;
   begin
      word   := lower(in_word);
      errors := text_ct();
      if word is not null then
         if length(word) < 5 or length(word) > 5 then
            add_error(word || ' does not have exactly 5 letters.');
         end if;
         if not exists_word(word) then
            add_error(word || ' is not in word list.');
         end if;
         if errors.count = 0 then
            pattern := util.pattern(lower(in_solution), word);
         end if;
         if in_hard_mode = 1 and in_previous_guess is not null then
            if in_previous_guess.is_valid = 0 then
               add_error('valid previous guess of '
                  || word
                  || ' is required in hard mode.');
            else
               check_hard_mode;
            end if;
         end if;
      end if;
      return;
   end guess_ot;

   -- -----------------------------------------------------------------------------------------------------------------
   -- is_valid (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member function is_valid return integer is
   begin
      return (
            case
               when errors is not null and errors.count = 0 and length(word) = 5 and length(pattern) = 5 then
                  1
               else
                  0
            end
         );
   end is_valid;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- containing_letters (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member function containing_letters return text_ct is
      t_letters text_ct := text_ct();
      l_letter  varchar2(1 char);
   begin
      <<letters>>
      for i in 1..length(pattern)
      loop
         if substr(pattern, i, 1) in ('1', '2') then
            l_letter := substr(word, i, 1);
            if not util.contains(in_text_ct => t_letters, in_entry => l_letter) then
               t_letters.extend;
               t_letters(t_letters.count) := l_letter;
            end if;
         end if;
      end loop letters;
      return t_letters;
   end containing_letters;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- missing_letters (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member function missing_letters(in_solution in varchar2) return text_ct is
      t_letters text_ct := text_ct();
      l_letter  varchar2(1 char);
   begin
      <<letters>>
      for i in 1..length(word)
      loop
         l_letter := substr(word, i, 1);
         if instr(in_solution, l_letter) = 0 then
            if not util.contains(in_text_ct => t_letters, in_entry => l_letter) then
               t_letters.extend;
               t_letters(t_letters.count) := l_letter;
            end if;
         end if;
      end loop letters;
      return t_letters;
   end missing_letters;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- like_pattern (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member function like_pattern return varchar2 is
      l_result varchar2(5);
   begin
      <<letters>>
      for i in 1..5
      loop
         if substr(pattern, i, 1) = '2' then
            l_result := l_result || substr(word, i, 1);
         else
            l_result := l_result || '_';
         end if;
      end loop letters;
      return l_result;
   end like_pattern;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- not_like_patterns (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member function not_like_patterns(in_solution in varchar2) return text_ct is
      t_result text_ct := text_ct();
   begin
      <<letters>>
      for i in 1..5
      loop
         if substr(pattern, i, 1) = '1'
            or substr(pattern, i, 1) = '0' and instr(in_solution, substr(word, i, 1)) > 0
         then
            t_result.extend;
            t_result(t_result.count) := rpad('_', i - 1, '_')
                                        || substr(word, i, 1)
                                        || rpad('_', 5 - i, '_');
         end if;
      end loop letters;
      return t_result;
   end not_like_patterns;
end;
/