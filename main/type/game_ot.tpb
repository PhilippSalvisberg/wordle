create or replace type body game_ot is
   -- -----------------------------------------------------------------------------------------------------------------
   -- game_ot (constructor)
   -- -----------------------------------------------------------------------------------------------------------------
   constructor function game_ot(
      self         in out nocopy game_ot,
      in_solution  in            varchar2,
      in_hard_mode in            integer,
      in_guesses   in            text_ct
   ) return self as result is
      o_guess         guess_ot;
      t_valid_guesses guess_ct;
   begin
      self.solution  := in_solution;
      self.hard_mode := in_hard_mode;
      self.guesses   := guess_ct();
      <<add_guesses>>
      for i in 1..in_guesses.count
      loop
         self.add_guess(in_guesses(i));
      end loop add_guesses;
      return;
   end game_ot;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- is_initialized (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member function is_initialized return integer is
   begin
      return (
         case
            when self.solution is not null
               and self.hard_mode is not null
               and self.guesses is not null
            then
               1
            else
               0
         end
      );
   end is_initialized;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- is_completed (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member function is_completed return integer is
      t_valid_guesses guess_ct;
   begin
      t_valid_guesses := self.valid_guesses();
      return (
         case
            when self.is_initialized = 1
               and t_valid_guesses.count > 0
               and t_valid_guesses(t_valid_guesses.count).pattern = '22222'
            then
               1
            else
               0
         end
      );
   end is_completed;

   -- -----------------------------------------------------------------------------------------------------------------
   -- errors (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member function errors return text_ct is
      t_errors text_ct := text_ct();
   begin
      <<add_errors>>
      for i in 1..guesses.count
      loop
         util.add_text_ct(io_text_ct => t_errors, in_text_ct => guesses(i).errors);
      end loop add_errors;
      return t_errors;
   end errors;
  
   -- -----------------------------------------------------------------------------------------------------------------
   -- add_guess (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member procedure add_guess(in_word in varchar2) is
      o_guess         guess_ot;
      t_valid_guesses guess_ct;
   begin
      t_valid_guesses        := self.valid_guesses();
      if t_valid_guesses.count = 0 then
         o_guess := guess_ot(in_word, self.solution, null, self.hard_mode);
      else
         o_guess := guess_ot(in_word, self.solution, t_valid_guesses(t_valid_guesses.count), self.hard_mode);
      end if;
      guesses.extend;
      guesses(guesses.count) := o_guess;
   end add_guess;

   -- -----------------------------------------------------------------------------------------------------------------
   -- valid_guesses (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member function valid_guesses return guess_ct is
      t_guesses guess_ct := guess_ct();
   begin
      <<add_valid_guesses>>
      for i in 1..guesses.count
      loop
         if guesses(i).is_valid = 1 then
            t_guesses.extend;
            t_guesses(t_guesses.count) := guesses(i);
         end if;
      end loop add_valid_guesses;
      return t_guesses;
   end valid_guesses;

   -- -----------------------------------------------------------------------------------------------------------------
   -- containing_letters (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member function containing_letters return text_ct is
      t_valid_guesses guess_ct;
      t_result        text_ct := text_ct();
   begin
      t_valid_guesses := self.valid_guesses;
      <<combine>>
      for i in 1..t_valid_guesses.count
      loop
         util.add_text_ct(io_text_ct => t_result, in_text_ct => t_valid_guesses(i).containing_letters);
      end loop combine;
      return t_result;
   end containing_letters;

   -- -----------------------------------------------------------------------------------------------------------------
   -- missing_letters (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member function missing_letters return text_ct is
      t_valid_guesses guess_ct;
      t_result        text_ct := text_ct();
   begin
      t_valid_guesses := self.valid_guesses;
      <<combine>>
      for i in 1..t_valid_guesses.count
      loop
         util.add_text_ct(io_text_ct => t_result, in_text_ct => t_valid_guesses(i).missing_letters(self.solution));
      end loop combine;
      return t_result;
   end missing_letters; 

   -- -----------------------------------------------------------------------------------------------------------------
   -- like_pattern (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member function like_pattern return varchar2 is
      t_valid_guesses guess_ct;
      t_like          text_ct := text_ct();
      l_pattern_char  varchar2(1);
      l_result        varchar2(5);
   begin
      t_valid_guesses := self.valid_guesses;
      <<populate_t_like>>
      for i in 1..t_valid_guesses.count
      loop
         t_like.extend;
         t_like(t_like.count) := t_valid_guesses(i).like_pattern;
      end loop populate_t_like;
      <<pattern_pos>>
      for i in 1..5
      loop
         <<combine>>
         for j in 1..t_like.count
         loop
            l_pattern_char := substr(t_like(j), i, 1);
            if (l_result is null or length(l_result) < i) and l_pattern_char != '_' then
               l_result := l_result || l_pattern_char;
            end if;
         end loop combine;
         if l_result is null or length(l_result) < i then
            l_result := l_result || '_';
         end if;
      end loop pattern_pos;
      return l_result;
   end like_pattern;

   -- -----------------------------------------------------------------------------------------------------------------
   -- not_like_patterns (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member function not_like_patterns return text_ct is
      t_valid_guesses guess_ct;
      t_result        text_ct := text_ct();
   begin
      t_valid_guesses := self.valid_guesses;
      <<combine>>
      for i in 1..t_valid_guesses.count
      loop
         util.add_text_ct(io_text_ct => t_result, in_text_ct => t_valid_guesses(i).not_like_patterns);
      end loop combine;
      return t_result;
   end not_like_patterns;

   -- -----------------------------------------------------------------------------------------------------------------
   -- suggestions_query (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member function suggestions_query(
      in_rows      in integer default 10,
      in_for_guess in integer default null
   ) return varchar2 is
      l_template_normal varchar2(4000 byte) := q'[with
   other_letters as (
      select w.word
        from words w
        join letter_in_words lw
          on lw.word = w.word
        join letters l
          on l.letter = lw.letter#ALL_LETTERS#
       group by w.word
      having count(*) >= 4
       order by count(*) desc,
             sum(l.is_vowel),
             sum(lw.occurrences * l.occurrences) desc,
             w.word
       fetch first 1 row only
   ),
   hard_mode as (
      select word
        from words
       where word like '#LIKE_PATTERN#'#NOT_LIKE_PATTERNS##WRONG_POS_MATCHES##NO_MATCHES##GUESS_LIST#
       order by case when game_id is not null then 0 else 1 end,
             distinct_letters desc,
             occurrences desc,
             word
       fetch first #SUGGESTIONS# rows only
   ),
   all_matcher as (
      select word
        from other_letters 
      union all 
      select word
        from hard_mode
   )
select word 
  from all_matcher
 fetch first #SUGGESTIONS# rows only]';
      l_template_hard   varchar2(4000 byte) := q'[with
   hard_mode as (
      select word
        from words
       where word like '#LIKE_PATTERN#'#NOT_LIKE_PATTERNS##WRONG_POS_MATCHES##NO_MATCHES##GUESS_LIST#
       order by case when game_id is not null then 0 else 1 end,
             distinct_letters desc,
             occurrences desc,
             word
   )
select word 
  from hard_mode
 fetch first #SUGGESTIONS# rows only]';
      l_query           varchar2(4000 byte);
      t_valid_guesses   guess_ct;
      o_game            game_ot;
      --
      function all_letters return varchar2 is
         l_list         text_ct;
         l_where_clause varchar2(4000 byte);
      begin
         if t_valid_guesses.count > 0 then
            l_list         := self.containing_letters;
            util.add_text_ct(io_text_ct => l_list, in_text_ct => self.missing_letters);
            l_where_clause := chr(10)
                              || '       where lw.letter not in ('
                              || util.to_csv(l_list)
                              || ')';
         end if;
         return l_where_clause;
      end all_letters;
      --
      function not_like_patterns return varchar2 is
         l_pred              varchar2(4000 byte);
         t_not_like_patterns text_ct;
      begin
         t_not_like_patterns := self.not_like_patterns;
         <<patterns>>
         for i in 1..t_not_like_patterns.count
         loop
            l_pred := l_pred
                      || chr(10)
                      || '         and word not like '''
                      || t_not_like_patterns(i)
                      || '''';
         end loop patterns;
         return l_pred;
      end not_like_patterns;
      --
      function wrong_pos_matches return varchar2 is
         l_pred               varchar2(4000 byte);
         t_containing_letters text_ct;
      begin
         t_containing_letters := self.containing_letters;
         <<letters>>
         for i in 1..t_containing_letters.count
         loop
            l_pred := l_pred
                      || chr(10)
                      || '         and instr(word, '''
                      || t_containing_letters(i)
                      || ''', 1, '
                      || regexp_count(self.solution, t_containing_letters(i))
                      || ') > 0';
         end loop letters;
         return l_pred;
      end wrong_pos_matches;
      --
      function no_matches return varchar2 is
         l_pred            varchar2(4000 byte);
         t_missing_letters text_ct;
      begin
         t_missing_letters := self.missing_letters;
         <<letters>>
         for i in 1..t_missing_letters.count
         loop
            l_pred := l_pred
                      || chr(10)
                      || '         and word not like ''%'
                      || t_missing_letters(i)
                      || '%''';
         end loop letters;
         return l_pred;
      end no_matches;
      --
      function guess_list return varchar2 is
         l_pred varchar2(4000 byte);
      begin
         if t_valid_guesses.count > 0 then
            l_pred := l_pred
                      || chr(10)
                      || '         and word not in (';
            <<not_in_pred>>
            for i in 1..t_valid_guesses.count
            loop
               if i > 1 then
                  l_pred := l_pred || ', ';
               end if;
               l_pred := l_pred
                         || ''''
                         || t_valid_guesses(i).word
                         || '''';
            end loop not_in_pred;
            l_pred := l_pred || ')';
         end if;
         return l_pred;
      end guess_list;
   begin
      t_valid_guesses := self.valid_guesses;
      if (in_for_guess is not null and t_valid_guesses.count > in_for_guess) then
         t_valid_guesses.trim(t_valid_guesses.count - in_for_guess);
         o_game  := game_ot(self.solution, self.hard_mode, t_valid_guesses);
         l_query := o_game.suggestions_query(in_rows);
      else
         if self.hard_mode = 0 and t_valid_guesses.count < 3 then
            l_query := l_template_normal;
            l_query := replace(l_query, '#ALL_LETTERS#', all_letters());
         else
            l_query := l_template_hard;
         end if;
         l_query := replace(l_query, '#LIKE_PATTERN#', self.like_pattern);
         l_query := replace(l_query, '#NOT_LIKE_PATTERNS#', not_like_patterns);
         l_query := replace(l_query, '#WRONG_POS_MATCHES#', wrong_pos_matches());
         l_query := replace(l_query, '#NO_MATCHES#', no_matches());
         l_query := replace(l_query, '#SUGGESTIONS#', in_rows);
         l_query := replace(l_query, '#GUESS_LIST#', guess_list());
      end if;
      return l_query;
   end suggestions_query;

   -- -----------------------------------------------------------------------------------------------------------------
   -- suggestions (member)
   -- -----------------------------------------------------------------------------------------------------------------
   member function suggestions(in_rows in integer default 10) return text_ct is
      t_suggestions text_ct;
   begin
      execute immediate suggestions_query(in_rows) bulk collect into t_suggestions;
      return t_suggestions;
   end suggestions;
end;
/
