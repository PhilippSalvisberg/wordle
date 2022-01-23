create or replace package body wordle is

   -- -----------------------------------------------------------------------------------------------------------------
   -- global variables & constants
   -- -----------------------------------------------------------------------------------------------------------------
   g_ansiconsole  boolean          := false;
   g_suggestions  integer          := 10;
   g_show_query   boolean          := true;
   co_max_guesses constant integer := 50; -- just limit them as a fail safe to reduce risk of endless loops

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
      l_solution      words.word%type := lower(in_solution);
      l_guess         words.word%type := lower(in_guess);
      l_pattern       words.word%type;
      l_solution_char varchar2(1);
      l_guess_char    varchar2(1);
      --
      procedure append(in_match in varchar2) is
      begin
         l_pattern := l_pattern || in_match;
      end append;
   begin
      <<process_characters>>
      for i in 1..length(l_solution)
      loop
         l_solution_char := substr(l_solution, i, 1);
         l_guess_char    := substr(l_guess, i, 1);
         if l_guess_char = l_solution_char then
            append('2');
         elsif instr(l_solution, l_guess_char) > 0 and instr(l_guess, l_guess_char) = i then
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
   -- play (public)
   -- -----------------------------------------------------------------------------------------------------------------
   function play(
      in_game_number in words.game_number%type,
      in_words       in word_ct,
      in_autoplay    in integer default 0
   ) return word_ct is
      l_game_number       words.game_number%type := in_game_number;
      t_words             word_ct                := in_words;
      t_rows              word_ct                := word_ct();
      l_first_suggestion  words.word%type;
      -- 
      type t_exact_type is table of varchar2(1) index by pls_integer;
      t_exact_matches     t_exact_type           := t_exact_type(1 => null, 2 => null, 3 => null, 4 => null, 5 => null);
      type t_char_type is table of varchar2(1) index by varchar2(1);
      t_wrong_pos_matches t_char_type            := t_char_type();
      t_no_matches        t_char_type            := t_char_type();
      --
      procedure append(in_row in varchar2) is
      begin
         t_rows.extend;
         t_rows(t_rows.count) := in_row;
      end append;
      -- 
      procedure add_matches(
         in_guess    in varchar2,
         in_pattern  in varchar2,
         in_solution in varchar2
      ) is
         l_pattern_char varchar2(1);
         l_guess_char   varchar2(1);
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
                  t_wrong_pos_matches(l_guess_char) := to_char(i);
               else
                  if instr(in_solution, l_guess_char) = 0 then
                     t_no_matches(l_guess_char) := l_guess_char;
                  end if;
            end case;
         end loop populate_query_predicate_input;
      end add_matches;
      --
      procedure evaluate_guesses is
         l_solution words.word%type;
         l_pattern  words.word%type;
         t_temp     word_ct;
      begin
         if l_game_number is null then
            l_game_number := game_number();
         end if;
         l_solution := solution(l_game_number);
         -- ensure that only known words are used, ignore wrong ones
         select w.word bulk collect into t_temp
           from table(t_words) i
           join words w
             on w.word = lower(i.column_value);
         t_words    := t_temp;
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
         l_pred varchar2(4000 char);
         l_char varchar2(1);
      begin
         l_char := t_wrong_pos_matches.first;
         <<add_like_predicates>>
         while l_char is not null
         loop
            l_pred := l_pred
                      || chr(10)
                      || '               and word like ''%'
                      || l_char
                      || '%'''
                      || chr(10)
                      || '               and word not like '''
                      || wrong_pos_pattern(l_char, to_number(t_wrong_pos_matches(l_char)))
                      || '''';
            l_char := t_wrong_pos_matches.next(l_char);
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
         exit autoplay_loop when completed() or in_autoplay != 1 or t_words.count > co_max_guesses;
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