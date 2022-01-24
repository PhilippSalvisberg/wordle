create or replace package body wordle is

   -- -----------------------------------------------------------------------------------------------------------------
   -- global variables & constants
   -- -----------------------------------------------------------------------------------------------------------------
   g_ansiconsole  boolean          := false;
   g_suggestions  integer          := 10;
   g_show_query   boolean          := true;
   g_hard_mode    boolean          := false;
   co_max_guesses constant integer := 20; -- just limit them as a fail safe to reduce risk of endless loops

   -- -----------------------------------------------------------------------------------------------------------------
   -- encode (private)
   -- -----------------------------------------------------------------------------------------------------------------
   function encode(
      in_word    in words.word%type,
      in_pattern in words.word%type
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
      procedure append_char(
         in_char  in varchar2,
         in_match in varchar2
      ) is
      begin
         if g_ansiconsole then
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
            append(in_char);
            append(' ');
            append(co_reset);
         else
            case in_match
               when '2' then
                  append('.');
                  append(in_char);
                  append('.');
               when '1' then
                  append('(');
                  append(in_char);
                  append(')');
               else
                  append('-');
                  append(in_char);
                  append('-');
            end case;
         end if;
      end append_char;
   begin
      <<process_pattern_positions>>
      for i in 1..length(in_word)
      loop
         append_char(upper(substr(in_word, i, 1)), substr(in_pattern, i, 1));
         if i < 5 then
            append(' '); -- character separator
         end if;
      end loop process_pattern_positions;
      return l_result;
   end encode;

   -- -----------------------------------------------------------------------------------------------------------------
   -- game_number (private)
   -- -----------------------------------------------------------------------------------------------------------------
   function game_number(in_game_on in date default trunc(sysdate)) return words.game_number%type is
      l_game_number words.game_number%type;
   begin
      select game_number
        into l_game_number
        from words
       where game_on = in_game_on
         and rownum = 1;
      return l_game_number;
   end game_number;

   -- -----------------------------------------------------------------------------------------------------------------
   -- solution (private)
   -- -----------------------------------------------------------------------------------------------------------------
   function solution(in_game_number in integer) return words.word%type is
      l_solution words.word%type;
   begin
      select word
        into l_solution
        from words
       where game_number = in_game_number;
      return l_solution;
   end solution;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- pattern (private)
   -- -----------------------------------------------------------------------------------------------------------------
   function pattern(
      in_solution in words.word%type,
      in_guess    in words.word%type
   ) return words.word%type
      deterministic
   is
      l_solution       words.word%type := lower(in_solution); -- NOSONAR: function call will not fail
      l_guess          words.word%type := lower(in_guess);    -- NOSONAR: function call will not fail
      type t_letter_type is table of pls_integer index by varchar2(1);
      t_solution_chars t_letter_type   := t_letter_type();
      t_guess_chars    t_letter_type   := t_letter_type();
      l_pattern        words.word%type;
      l_solution_char  varchar2(1);
      l_guess_char     varchar2(1);
      --
      procedure add_char(in_chars in out t_letter_type,
                         in_char  in     varchar2) is
      begin
         if in_chars.exists(in_char) then
            in_chars(in_char) := in_chars(in_char) + 1;
         else
            in_chars(in_char) := 1;
         end if;
      end add_char;
      --
      procedure append(in_match in varchar2) is
      begin
         l_pattern := l_pattern || in_match;
      end append;
      --
      function number_of_guessed_char(
         in_solution in varchar2,
         in_guess    in varchar,
         in_char     in varchar
      ) return integer is
         l_result integer := 0;
      begin
         for i in 1..length(in_solution)
         loop
            if substr(in_solution, i, 1) = in_char and substr(in_guess, i, 1) = in_char then
               l_result := l_result + 1;
            end if;
         end loop;
         return l_result;
      end number_of_guessed_char;
   begin
      <<count_letter_occurrences_in_solution>>
      for i in 1..length(l_solution)
      loop
         add_char(t_solution_chars, substr(l_solution, i, 1));
      end loop count_letter_occurrences_in_solution;

      <<process_characters>>
      for i in 1..length(l_solution)
      loop
         l_solution_char := substr(l_solution, i, 1);
         l_guess_char    := substr(l_guess, i, 1);
         add_char(t_guess_chars, l_guess_char);
         if l_guess_char = l_solution_char then
            append('2');
         elsif instr(l_solution, l_guess_char) > 0
            and (t_solution_chars(l_guess_char)
               - number_of_guessed_char(l_solution, l_guess, l_guess_char)
               - t_guess_chars(l_guess_char) >= 0)
         then
            append('1');
         else
            append('0');
         end if;
      end loop process_characters;
      return l_pattern;
   end pattern;

   -- -----------------------------------------------------------------------------------------------------------------
   -- set_ansiconsole (public)
   -- -----------------------------------------------------------------------------------------------------------------
   procedure set_ansiconsole(in_ansiconsole in boolean default true) is
   begin
      g_ansiconsole := in_ansiconsole;
   end set_ansiconsole;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- set_suggestions (public)
   -- -----------------------------------------------------------------------------------------------------------------
   procedure set_suggestions(in_suggestions in integer default 10) is
   begin
      g_suggestions := in_suggestions;
   end set_suggestions;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- set_show_query (public)
   -- -----------------------------------------------------------------------------------------------------------------
   procedure set_show_query(in_show_query in boolean default true) is
   begin
      g_show_query := in_show_query;
   end set_show_query;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- set_hard_mode (public)
   -- -----------------------------------------------------------------------------------------------------------------
   procedure set_hard_mode(in_hard_mode boolean default false) is
   begin
      g_hard_mode := in_hard_mode;
   end set_hard_mode;

   -- -----------------------------------------------------------------------------------------------------------------
   -- play (public)
   -- -----------------------------------------------------------------------------------------------------------------
   function play(
      in_game_number in words.game_number%type,
      in_words       in word_ct,
      in_autoplay    in integer default 0
   ) return word_ct is
      l_game_number       words.game_number%type := in_game_number;
      l_solution          words.word%type;
      t_words             word_ct                := in_words;
      t_rows              word_ct                := word_ct();
      l_first_suggestion  words.word%type;
      l_loop_counter      integer                := 0;
      -- 
      type t_exact_type is table of varchar2(1) index by pls_integer;
      t_exact_matches     t_exact_type           := t_exact_type(1 => null, 2 => null, 3 => null, 4 => null, 5 => null);
      type t_num_list_type is table of pls_integer;
      type t_char_type is table of t_num_list_type index by varchar2(1);
      t_wrong_pos_matches t_char_type            := t_char_type();
      t_no_matches        t_char_type            := t_char_type();
      --
      procedure append(in_row in varchar2) is
      begin
         t_rows.extend;
         t_rows(t_rows.count) := in_row;
      end append;
      --
      function position_added(
         in_num_list in t_num_list_type,
         in_pos      in integer
      ) return boolean is
         l_found boolean := false;
      begin
         <<look_for_pos>>
         for i in 1..in_num_list.count
         loop
            if in_num_list(i) = in_pos then
               l_found := true;
               exit look_for_pos;
            end if;
         end loop look_for_pos;
         return l_found;
      end position_added;
      --
      procedure add_matches(
         in_guess    in varchar2,
         in_pattern  in varchar2,
         in_solution in varchar2
      ) is
         l_pattern_char varchar2(1);
         l_guess_char   varchar2(1);
         t_num_list     t_num_list_type;
         l_found        integer;
      begin
         <<populate_query_predicate_input>>
         for i in 1..length(in_pattern)
         loop
            l_guess_char   := lower(substr(in_guess, i, 1));
            l_pattern_char := substr(in_pattern, i, 1);
            case l_pattern_char
               when '2' then
                  t_exact_matches(i) := l_guess_char;
               when '1' then
                  if t_wrong_pos_matches.exists(l_guess_char) then
                     t_num_list := t_wrong_pos_matches(l_guess_char);
                     if not position_added(t_num_list, i) then
                        t_num_list.extend;
                        t_num_list(t_num_list.count)      := i;
                        t_wrong_pos_matches(l_guess_char) := t_num_list;
                     end if;
                  else
                     t_wrong_pos_matches(l_guess_char) := t_num_list_type(i);
                  end if;
               else
                  if instr(in_solution, l_guess_char) = 0 then
                     t_no_matches(l_guess_char) := t_num_list_type(i);
                  end if;
            end case;
         end loop populate_query_predicate_input;
      end add_matches;
      --
      procedure remove_and_save_unknown_words(io_errors in out word_ct) is
         t_sanitised_input word_ct := word_ct();
      begin
         for r in (
            select i.column_value as input_word, w.word
              from table(t_words) i
              left join words w
                on w.word = lower(i.column_value)
             where i.column_value is not null
         )
         loop
            if r.word is null then
               io_errors.extend;
               io_errors(io_errors.count) := r.input_word || ' is not in word list.';
            else
               t_sanitised_input.extend;
               t_sanitised_input(t_sanitised_input.count) := r.word;
            end if;
         end loop;
         t_words := t_sanitised_input;
      end remove_and_save_unknown_words;
      --
      function number_of_chars_in_guess(
         in_guess   in varchar2,
         in_pattern in varchar2,
         in_char    in varchar2
      ) return integer is
         i_count integer := 0;
      begin
         <<positions>>
         for i in 1..5
         loop
            if substr(in_guess, i, 1) = in_char then
               if substr(in_pattern, i, 1) in ('2', '1') then
                  i_count := i_count + 1;
               end if;
            end if;
         end loop positions;
         return i_count;
      end number_of_chars_in_guess;
      --
      procedure remove_and_save_invalid_guesses(io_errors in out word_ct) is
         t_sanitised_input word_ct := word_ct();
         t_guesses         word_ct := word_ct();
         t_patterns        word_ct := word_ct();
         l_match           varchar2(1);
         l_char            varchar2(1);
         l_error           boolean := false;
      begin
         if g_hard_mode then
            <<words>>
            for i in 1..t_words.count
            loop
               <<guesses>>
               for j in 1..t_guesses.count
               loop
                  <<letters>>
                  for k in 1..5
                  loop
                     l_match := substr(t_patterns(j), k, 1);
                     l_char  := substr(t_guesses(j), k, 1);
                     if l_match = 2 and l_char != substr(t_words(i), k, 1) then
                        io_errors.extend;
                        io_errors(io_errors.count) := t_words(i)
                                                      || '''s letter #'
                                                      || k
                                                      || ' is not a '
                                                      || upper(l_char)
                                                      || '.';
                        l_error                    := true;
                     elsif l_match = 1 and regexp_count(t_words(i), l_char)
                        < number_of_chars_in_guess(t_guesses(j), t_patterns(j), l_char)
                     then
                        io_errors.extend;
                        io_errors(io_errors.count) := t_words(i)
                                                      || ' does not contain letter '
                                                      || upper(l_char)
                                                      || ' ('
                                                      || regexp_count(t_guesses(j), l_char)
                                                      || ' times).';
                        l_error                    := true;
                     end if;
                  end loop letters;
               end loop guesses;
               if not l_error then
                  t_guesses.extend;
                  t_guesses(t_guesses.count)                 := t_words(i);
                  t_patterns.extend;
                  t_patterns(t_patterns.count)               := pattern(l_solution, t_words(i));
                  t_sanitised_input.extend;
                  t_sanitised_input(t_sanitised_input.count) := t_words(i);
               end if;
               l_error := false;
            end loop words;
            t_words := t_sanitised_input;
         end if;
      end remove_and_save_invalid_guesses;
      --
      procedure print_errors(in_errors in word_ct) is
      begin
         if in_errors.count > 0 then
            append('reduced input due to the following errors:');
            for i in 1..in_errors.count
            loop
               append('- ' || in_errors(i));
            end loop;
            append(null);
         end if;
      end print_errors;
      --
      procedure evaluate_guesses is
         l_pattern words.word%type;
         t_temp    word_ct;
         t_errors  word_ct := word_ct();
      begin
         if l_game_number is null then
            l_game_number := game_number();
         end if;
         l_solution := solution(l_game_number);
         remove_and_save_unknown_words(t_errors);
         remove_and_save_invalid_guesses(t_errors);
         print_errors(t_errors);
         <<process_guesses>>
         for i in 1..t_words.count
         loop
            l_pattern := pattern(l_solution, t_words(i));
            append(encode(t_words(i), l_pattern));
            add_matches(t_words(i), l_pattern, l_solution);
         end loop process_guesses;
      end evaluate_guesses;
      --
      function exact_matches return varchar2 is
         l_pred varchar2(5 char);
      begin
         <<process_positions_in_word>>
         for i in 1..5
         loop
            if t_exact_matches(i) is not null then
               l_pred := l_pred || t_exact_matches(i);
            else
               l_pred := l_pred || '_';
            end if;
         end loop process_positions_in_word;
         return l_pred;
      end exact_matches;
      --
      function wrong_pos_pattern(
         in_char in varchar2,
         in_pos  in integer
      ) return varchar2 is
         l_pattern varchar2(5 char);
      begin
         for i in 1..5
         loop
            if i = in_pos then
               l_pattern := l_pattern || in_char;
            else
               l_pattern := l_pattern || '_';
            end if;
         end loop;
         return l_pattern;
      end wrong_pos_pattern;
      --
      function wrong_pos_matches return varchar2 is
         l_pred     varchar2(4000 char);
         l_char     varchar2(1);
         t_num_list t_num_list_type;
      begin
         l_char := t_wrong_pos_matches.first;
         <<add_like_predicates>>
         while l_char is not null
         loop
            l_pred     := l_pred
                          || chr(10)
                          || '               and instr(word, '''
                          || l_char
                          || ''', 1, '
                          || regexp_count(l_solution, l_char)
                          || ') > 0';
            t_num_list := t_wrong_pos_matches(l_char);
            for i in 1..t_num_list.count
            loop
               l_pred := l_pred
                         || chr(10)
                         || '               and word not like '''
                         || wrong_pos_pattern(l_char, t_num_list(i))
                         || '''';
            end loop;
            l_char     := t_wrong_pos_matches.next(l_char);
         end loop add_like_predicates;
         return l_pred;
      end wrong_pos_matches;
      --
      function no_matches return varchar2 is
         l_pred varchar2(4000 char);
         l_char varchar2(1);
      begin
         l_char := t_no_matches.first;
         <<add_not_like_predicate>>
         while l_char is not null
         loop
            l_pred := l_pred
                      || chr(10)
                      || '               and word not like ''%'
                      || l_char
                      || '%''';
            l_char := t_no_matches.next(l_char);
         end loop add_not_like_predicate;
         return l_pred;
      end no_matches;
      --
      function guess_list return varchar2 is
         l_pred varchar2(4000 char);
      begin
         if t_words.count > 0 then
            l_pred := l_pred
                      || chr(10)
                      || '               and word not in (';
            <<add_not_in_predicate>>
            for i in 1..t_words.count
            loop
               if i > 1 then
                  l_pred := l_pred || ', ';
               end if;
               l_pred := l_pred
                         || ''''
                         || t_words(i)
                         || '''';
            end loop add_not_in_predicate;
            l_pred := l_pred || ')';
         end if;
         return l_pred;
      end guess_list;
      --
      procedure populate_suggestions is
         l_query_template varchar2(32767 byte) := q'[
            select word
              from words
             where word like '#EXACT_MATCHES#'#WRONG_POS_MATCHES##NO_MATCHES##GUESS_LIST#
             order by case when game_number is not null then 0 else 1 end, word
             fetch first #SUGGESTIONS# rows only]';
         l_query          varchar2(32767 byte);
         c_cursor         sys_refcursor;
         l_word           words.word%type;
      begin
         l_query := replace(l_query_template, '#EXACT_MATCHES#', exact_matches());
         l_query := replace(l_query, '#WRONG_POS_MATCHES#', wrong_pos_matches());
         l_query := replace(l_query, '#NO_MATCHES#', no_matches());
         l_query := replace(l_query, '#SUGGESTIONS#', g_suggestions);
         l_query := replace(l_query, '#GUESS_LIST#', guess_list());
         if g_show_query then
            append(replace(l_query, '            ', null)); -- remove left margin
         else
            append(null);
            append('suggestions:');
            append(null);
         end if;
         open c_cursor for l_query;
         <<process_suggestions>>
         loop
            fetch c_cursor into l_word;
            exit process_suggestions when c_cursor%notfound;
            append(l_word);
            if in_autoplay = 1 and l_first_suggestion is null then
               l_first_suggestion := l_word;
            end if;
         end loop process_suggestions;
         close c_cursor;
      end populate_suggestions;
      --
      function completed return boolean is
      begin
         return (t_exact_matches(1) is not null
            and t_exact_matches(2) is not null
            and t_exact_matches(3) is not null
            and t_exact_matches(4) is not null
            and t_exact_matches(5) is not null);
      end completed;
      -- 
      procedure auto_extend_word_list is
      begin
         if in_autoplay = 1 and l_first_suggestion is not null then
            t_words.extend;
            t_words(t_words.count) := l_first_suggestion;
            append(null);
            append('autoplay added: '
               || l_first_suggestion
               || ' ('
               || t_words.count
               || ')');
            append(null);
         end if;
         l_first_suggestion := null;
      end auto_extend_word_list;
   begin
      <<autoplay_loop>>
      loop
         l_loop_counter := l_loop_counter + 1;
         evaluate_guesses;
         if completed() then
            append(null);
            append('Bravo! You completed Wordle '
               || l_game_number
               || ' '
               || t_words.count
               || '/6');
         elsif g_suggestions > 0 then
            populate_suggestions;
            auto_extend_word_list;
         end if;
         exit autoplay_loop when completed() or in_autoplay != 1 or l_loop_counter > co_max_guesses;
      end loop autoplay_loop;
      return t_rows;
   end play;

   -- -----------------------------------------------------------------------------------------------------------------
   -- play (public, convenience)
   -- -----------------------------------------------------------------------------------------------------------------
   function play(
      in_game_number in words.game_number%type,
      in_word1       in words.word%type,
      in_word2       in words.word%type default null,
      in_word3       in words.word%type default null,
      in_word4       in words.word%type default null,
      in_word5       in words.word%type default null,
      in_word6       in words.word%type default null
   ) return word_ct is
   begin
      return play(in_game_number, word_ct(in_word1, in_word2, in_word3, in_word4, in_word5, in_word6));
   end play;

   -- -----------------------------------------------------------------------------------------------------------------
   -- play (public, convenience)
   -- -----------------------------------------------------------------------------------------------------------------
   function play(
      in_word1 in words.word%type,
      in_word2 in words.word%type default null,
      in_word3 in words.word%type default null,
      in_word4 in words.word%type default null,
      in_word5 in words.word%type default null,
      in_word6 in words.word%type default null
   ) return word_ct is
   begin
      return play(null, word_ct(in_word1, in_word2, in_word3, in_word4, in_word5, in_word6));
   end play;

   -- -----------------------------------------------------------------------------------------------------------------
   -- autoplay (public, convenience)
   -- -----------------------------------------------------------------------------------------------------------------
   function autoplay(
      in_game_number in words.game_number%type,
      in_word1       in words.word%type default null,
      in_word2       in words.word%type default null,
      in_word3       in words.word%type default null,
      in_word4       in words.word%type default null,
      in_word5       in words.word%type default null,
      in_word6       in words.word%type default null
   ) return word_ct is
   begin
      return play(in_game_number, word_ct(in_word1, in_word2, in_word3, in_word4, in_word5, in_word6), 1);
   end autoplay;

   -- -----------------------------------------------------------------------------------------------------------------
   -- autoplay (public, convenience)
   -- -----------------------------------------------------------------------------------------------------------------
   function autoplay(
      in_word1 in words.word%type default null,
      in_word2 in words.word%type default null,
      in_word3 in words.word%type default null,
      in_word4 in words.word%type default null,
      in_word5 in words.word%type default null,
      in_word6 in words.word%type default null
   ) return word_ct is
   begin
      return play(null, word_ct(in_word1, in_word2, in_word3, in_word4, in_word5, in_word6), 1);
   end autoplay;

end wordle;
/
