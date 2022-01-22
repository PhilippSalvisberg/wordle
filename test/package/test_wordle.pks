create or replace package test_wordle is
   --%suite
   
   --%context(configuration)

   --%test(enable ANSI console and start play)
   procedure set_ansiconsole;

   --%test(reduce suggestions to one without showing query)
   procedure set_suggestions;

   --%test(show query to retrieve suggestions)
   procedure set_show_query;
   
   --%endcontext
   
   --%context(play)

   --%test(play Wordle 213 first attempt)
   procedure play_213_1;

   --%test(play Wordle 213 second attempt)
   procedure play_213_2;

   --%test(play Wordle 213 third attempt)
   procedure play_213_3;

   --%test(play Wordle 213 forth attempt)
   procedure play_213_4;

   --%test(play Wordle 213 fifth attempt and solved)
   procedure play_213_5;
   
   --%test(consider wrong positions in suggestions)
   procedure play_consider_wrong_positions_in_suggestions;
   
   --%endcontext

end test_wordle;
/
