create or replace view full_autoplay_results AS
with
   function config return integer is
   begin
      wordle.set_ansiconsole(false);
      wordle.set_suggestions(1);
      wordle.set_show_query(true);
      return 1;
   end;
   function input_from_evaluation_result(
      in_evaluation_result in varchar2
   ) return varchar2 is
      l_result varchar2(1000 char);
   begin
      l_result := replace(in_evaluation_result, ' ', null);
      l_result := replace(l_result, '.', null);
      l_result := replace(l_result, '(', null);
      l_result := replace(l_result, ')', null);
      l_result := replace(l_result, '-', null);
      return l_result;
   end input_from_evaluation_result;
   games as (
      select game_number, word
        from words
       where game_number is not null
         and config() is not null
       order by game_number
   ),
   plays as (
      select rownum as line,
             autoplay.column_value as text,
             games.game_number,
             games.word as solution
        from games
       cross apply wordle.autoplay(games.game_number) autoplay
   ),
   plays_bravo as (
      select line,
             text,
             game_number,
             solution,
             to_number(regexp_substr(text, '^(\D+)(\d+)\s+(\d+)\/(\d+)$', 1, 1, null, 3)) as guesses
        from plays
       where text like 'Bravo!%'
   ),
   plays_detail as (
      select /*+ ordered use_hash(b) use_hash(q) */ a.line,
             a.game_number,
             a.solution,
             a.guesses,
             round(100 * count(case
                      when guesses > 6 then
                         1
                   end) over () / count(*) over (), 2) as too_many_guesses_percent,
             xmltype(
                xmlserialize(
                   document xmlelement("details",
                      xmlelement("guesses",
                         xmlagg(
                            xmlelement("guess",
                               xmlelement("input", input_from_evaluation_result(b.text)),
                               xmlelement("result", b.text)
                            ) order by b.line
                         )
                      ),
                      xmlelement("lastQuery", xmlcdata(q.text))
                   ) as clob indent size = 4
                )
             ) as details
        from plays_bravo a
        join plays b
          on b.game_number = a.game_number
         and b.line between a.line - a.guesses - 1 and a.line - 2
        join plays q
          on q.line = a.line - a.guesses - 6
       group by a.line,
             a.game_number,
             a.solution,
             a.guesses,
             q.text
   )
select game_number, guesses, too_many_guesses_percent, details
  from plays_detail;
/