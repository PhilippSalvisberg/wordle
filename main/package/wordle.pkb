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
      in_word    in varchar2,
      in_pattern in varchar2
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
   function game_number(in_game_on in date default trunc(sysdate)) return integer is
      l_game_number integer;
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
   function solution(in_game_number in integer) return varchar2 is
      l_solution varchar2(5);
   begin
      select word
        into l_solution
        from words
       where game_number = in_game_number;
      return l_solution;
   end solution;
   
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
      in_game_number in integer,
      in_words       in text_ct,
      in_autoplay    in integer default 0
   ) return text_ct is
      l_loop_counter integer := 0;
      l_game_number  integer := in_game_number;
      o_game         game_ot;
      t_rows         text_ct := text_ct();
      t_suggestions  text_ct;
      --
      procedure append(in_row in varchar2 default null) is
      begin
         t_rows.extend;
         t_rows(t_rows.count) := in_row;
      end append;
      --
      procedure print_errors is
         t_errors text_ct;
      begin
         t_errors := o_game.errors();
         if t_errors.count > 0 then
            append('reduced input due to the following errors:');
            <<errors>>
            for i in 1..t_errors.count
            loop
               append('- ' || t_errors(i));
            end loop errors;
            append();
         end if;
      end print_errors;
      --
      procedure print_evaluation is
         t_guesses guess_ct;
      begin
         t_guesses := o_game.valid_guesses();
         if t_guesses.count > 0 then
            <<guesses>>
            for i in 1..t_guesses.count
            loop
               append(encode(t_guesses(i).word, t_guesses(i).pattern));
            end loop guesses;
         end if;
      end print_evaluation;
      --
      procedure print_suggestions is
      begin
         append();
         if g_show_query then
            append(o_game.suggestions_query(g_suggestions));
         else
            append('suggestions:');
            append();
         end if;
         <<suggestions>>
         for i in 1..t_suggestions.count
         loop
            append(t_suggestions(i));
         end loop suggestions;
      end print_suggestions;
      --
      procedure print_final_line is
      begin
         append();
         append(
            'Bravo! You completed Wordle '
            || l_game_number
            || ' '
            || o_game.valid_guesses().count
            || '/6');
      end print_final_line;
      --
      procedure autoguess is
      begin
         if in_autoplay = 1 then
            o_game.add_guess(t_suggestions(1));
            append(null);
            append('autoplay added: '
               || t_suggestions(1)
               || ' ('
               || o_game.valid_guesses().count
               || ')');
            append(null);
         end if;
      end autoguess;
   begin
      if l_game_number is null then
         l_game_number := game_number();
      end if;
      o_game := game_ot(
                   solution(l_game_number),
                   case
                      when g_hard_mode then
                         1
                      else
                         0
                   end,
                   in_words
                );
      print_errors;
      <<autoplay_loop>>
      loop
         l_loop_counter := l_loop_counter + 1;
         print_evaluation;
         if o_game.is_completed() = 1 then
            print_final_line;
            exit autoplay_loop;
         elsif g_suggestions > 0 then
            t_suggestions := o_game.suggestions(g_suggestions);
            if t_suggestions.count > 0 then
               print_suggestions();
               autoguess;
            end if;
         end if;
         exit autoplay_loop when in_autoplay != 1 or l_loop_counter > co_max_guesses;
      end loop autoplay_loop;
      return t_rows;
   end play;

   -- -----------------------------------------------------------------------------------------------------------------
   -- play (public, convenience)
   -- -----------------------------------------------------------------------------------------------------------------
   function play(
      in_game_number in integer,
      in_word1       in varchar2,
      in_word2       in varchar2 default null,
      in_word3       in varchar2 default null,
      in_word4       in varchar2 default null,
      in_word5       in varchar2 default null,
      in_word6       in varchar2 default null
   ) return text_ct is
   begin
      return play(in_game_number, text_ct(in_word1, in_word2, in_word3, in_word4, in_word5, in_word6));
   end play;

   -- -----------------------------------------------------------------------------------------------------------------
   -- play (public, convenience)
   -- -----------------------------------------------------------------------------------------------------------------
   function play(
      in_word1 in varchar2,
      in_word2 in varchar2 default null,
      in_word3 in varchar2 default null,
      in_word4 in varchar2 default null,
      in_word5 in varchar2 default null,
      in_word6 in varchar2 default null
   ) return text_ct is
   begin
      return play(null, text_ct(in_word1, in_word2, in_word3, in_word4, in_word5, in_word6));
   end play;

   -- -----------------------------------------------------------------------------------------------------------------
   -- autoplay (public, convenience)
   -- -----------------------------------------------------------------------------------------------------------------
   function autoplay(
      in_game_number in integer,
      in_word1       in varchar2 default null,
      in_word2       in varchar2 default null,
      in_word3       in varchar2 default null,
      in_word4       in varchar2 default null,
      in_word5       in varchar2 default null,
      in_word6       in varchar2 default null
   ) return text_ct is
   begin
      return play(in_game_number, text_ct(in_word1, in_word2, in_word3, in_word4, in_word5, in_word6), 1);
   end autoplay;

   -- -----------------------------------------------------------------------------------------------------------------
   -- autoplay (public, convenience)
   -- -----------------------------------------------------------------------------------------------------------------
   function autoplay(
      in_word1 in varchar2 default null,
      in_word2 in varchar2 default null,
      in_word3 in varchar2 default null,
      in_word4 in varchar2 default null,
      in_word5 in varchar2 default null,
      in_word6 in varchar2 default null
   ) return text_ct is
   begin
      return play(null, text_ct(in_word1, in_word2, in_word3, in_word4, in_word5, in_word6), 1);
   end autoplay;
end wordle;
/
