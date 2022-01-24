create or replace package test_wordle is
   --%suite
   
   --%beforeeach
   procedure reset_package_config;
   
   --%context(configuration)

   --%test(enable ANSI console and start play)
   procedure set_ansiconsole;

   --%test(reduce suggestions to one without showing query)
   procedure set_suggestions;

   --%test(show query to retrieve suggestions)
   procedure set_show_query;
   
   --%test(force reuse of known letters in hard mode)
   procedure set_hard_mode;
   
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
   
   --%endcontext

   --%context(fetatures)

   --%test(consider wrong positions in suggestions)
   procedure play_consider_wrong_positions_in_suggestions;
   
   --%test(consider number of letters in suggestions)
   procedure play_consider_number_of_letters_in_suggestions;

   --%endcontext

   --%context(bug fixes)

   --%test(consider wrong positions in suggestions for repeated letters)
   procedure play_consider_wrong_positions_in_suggestions_for_repeated_letters;

   --%test(consider occurrences of repeated letters)
   procedure play_consider_occurrences_of_repeated_letters;
   
   --%endcontext

end test_wordle;
/
