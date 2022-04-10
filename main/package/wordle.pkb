create or replace package body wordle is
   -- -----------------------------------------------------------------------------------------------------------------
   -- global variables & constants
   -- -----------------------------------------------------------------------------------------------------------------
   g_ansiconsole  boolean          := false;
   g_suggestions  integer          := 10;
   g_show_query   boolean          := false;
   g_hard_mode    boolean          := false;
   co_max_guesses constant integer := 20; -- just limit them as a fail safe to reduce risk of endless loops

   -- -----------------------------------------------------------------------------------------------------------------
   -- game_id (private)
   -- -----------------------------------------------------------------------------------------------------------------
   function game_id(in_game_date in date default trunc(sysdate)) return integer is
      l_game_id integer;
   begin
      select game_id
        into l_game_id
        from words
       where game_date = in_game_date;
      return l_game_id;
   exception
      when no_data_found or too_many_rows then
         raise;
   end game_id;

   -- -----------------------------------------------------------------------------------------------------------------
   -- solution (private)
   -- -----------------------------------------------------------------------------------------------------------------
   function solution(in_game_id in integer) return varchar2 is
      l_solution words.word%type;
   begin
      select word
        into l_solution
        from words
       where game_id = in_game_id;
      return l_solution;
   exception
      when no_data_found or too_many_rows then
         raise;
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
   procedure set_hard_mode(in_hard_mode in boolean default true) is
   begin
      g_hard_mode := in_hard_mode;
   end set_hard_mode;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- bulkplay (public)
   -- -----------------------------------------------------------------------------------------------------------------
   function bulkplay(
      in_from_game_id in integer default null,
      in_to_game_id   in integer default null
   ) return xmltype is
      t_games game_ct := game_ct();
      --
      procedure solve(in_solution in varchar2) is
         o_game         game_ot;
         t_suggestions  text_ct;
         l_loop_counter integer := 0;
      begin
         o_game                 := game_ot(in_solution, util.bool_to_int(g_hard_mode), text_ct());
         <<autoplay_loop>>
         loop
            l_loop_counter := l_loop_counter + 1;
            t_suggestions  := o_game.suggestions(g_suggestions);
            if t_suggestions.count > 0 then
               o_game.add_guess(t_suggestions(1));
            end if;
            exit autoplay_loop when o_game.is_completed() = 1 or l_loop_counter > co_max_guesses;
         end loop autoplay_loop;
         t_games.extend;
         t_games(t_games.count) := o_game;
      end solve;
      --
      function create_xmldoc return xmltype is
         l_doc xmltype;
      begin
         with
            games as (
               select w.game_id,
                      g.solution,
                      g.hard_mode,
                      g.is_completed() as is_completed,
                      (select count(*) from g.valid_guesses()) as number_of_guesses, -- NOSONAR G-3120: false postive
                      g.guesses as guesses,
                      g.object_value as game
                 from table(t_games) g
                 join words w
                   on w.word = g.solution
            ),
            aggr as (
               select max(hard_mode) as hard_mode,
                      count(*) as number_of_games,
                      sum(is_completed) as number_of_completed_games,
                      sum(case
                             when number_of_guesses > 6 then
                                1
                             else
                                0
                          end) as games_with_too_many_tries
                 from games
            ),
            calc as (
               select hard_mode,
                      number_of_games,
                      number_of_completed_games,
                      games_with_too_many_tries,
                      round(100 * (number_of_completed_games - games_with_too_many_tries) / number_of_games, 2) as solved_games_percent
                 from aggr
            )
         select xmltype(
                   xmlserialize(
                      document xmlelement("bulkplay",
                         xmlelement("hard_mode", hard_mode),
                         xmlelement("number_of_games", number_of_games),
                         xmlelement("number_of_completed_games", number_of_completed_games),
                         xmlelement("games_with_too_many_tries", games_with_too_many_tries),
                         xmlelement("solved_games_percent", solved_games_percent),
                         xmlelement("games",
                            (
                               select xmlagg(
                                         xmlelement("game",
                                            xmlelement("game_id", game_id),
                                            xmlelement("number_of_guesses", number_of_guesses),
                                            xmlelement("is_completed", is_completed),
                                            xmlelement("guesses",
                                               (
                                                  select xmlagg(
                                                            xmlelement("guess", util.encode(g.word, g.pattern, 0))
                                                         )
                                                    from table(guesses) g
                                               )
                                            ),
                                            xmlelement("queryBeforeLastAttempt",
                                               case
                                                  when g.number_of_guesses > 6 then
                                                     xmlcdata(chr(10)
                                                        || g.game.suggestions_query(in_rows => 10, in_for_guess => 5)
                                                        || chr(10))
                                                  else
                                                     null
                                               end
                                            )
                                         ) order by number_of_guesses desc, game_id
                                      )
                                 from games g
                            )
                         )
                      ) as clob indent size = 4
                   )
                ) as doc
           into l_doc
           from calc;
         return l_doc; -- NOSONAR G-7430: nested function, false postive
      exception
         when no_data_found or too_many_rows then
            raise;
      end create_xmldoc;
   begin
      -- main 
      <<games>>
      for r_game in (
         with
            boundaries as (
               select min(game_id) as min_game_id,
                      max(game_id) as max_game_id
                 from words
            )
         select words.word
           from words
          cross join boundaries
          where game_id between coalesce(in_from_game_id, min_game_id) and coalesce(in_to_game_id, max_game_id)
      )
      loop
         solve(r_game.word);
      end loop games;
      return create_xmldoc; -- NOSONAR G-7430: nested function, false postive
   end bulkplay;

   -- -----------------------------------------------------------------------------------------------------------------
   -- play (public)
   -- -----------------------------------------------------------------------------------------------------------------
   function play(
      in_game_id  in integer,
      in_words    in text_ct,
      in_autoplay in integer default 0
   ) return text_ct is
      l_loop_counter integer := 0;
      l_game_id      integer := in_game_id;
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
               append(util.encode(t_guesses(i).word, t_guesses(i).pattern, util.bool_to_int(g_ansiconsole)));
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
            || l_game_id
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
      if l_game_id is null then
         l_game_id := game_id();
      end if;
      o_game := game_ot(solution(l_game_id), util.bool_to_int(g_hard_mode), in_words);
      print_errors;
      <<autoplay_loop>>
      loop
         l_loop_counter := l_loop_counter + 1;
         print_evaluation;
         if o_game.is_completed() = 1 then
            print_final_line;
            exit autoplay_loop; -- NOSONAR: G-4375: repeating if condition does not make sense (false positive)
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
      in_game_id in integer,
      in_word1   in varchar2,
      in_word2   in varchar2 default null,
      in_word3   in varchar2 default null,
      in_word4   in varchar2 default null,
      in_word5   in varchar2 default null,
      in_word6   in varchar2 default null
   ) return text_ct is
   begin
      return play(in_game_id, text_ct(in_word1, in_word2, in_word3, in_word4, in_word5, in_word6));
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
      in_game_id in integer,
      in_word1   in varchar2 default null,
      in_word2   in varchar2 default null,
      in_word3   in varchar2 default null,
      in_word4   in varchar2 default null,
      in_word5   in varchar2 default null,
      in_word6   in varchar2 default null
   ) return text_ct is
   begin
      return play(in_game_id, text_ct(in_word1, in_word2, in_word3, in_word4, in_word5, in_word6), 1);
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