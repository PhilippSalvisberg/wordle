create or replace package test_game_ot is
   --%suite(game_ot)
   --%suitepath(wordle.internal)
   
   --%context(constructor)

   --%test(create completed game_ot)
   procedure constructor_completed;
   
   --%test(create not completed game_ot)
   procedure constructor_not_completed;

   --%endcontext

   --%context(member)

   --%test(returns errors of all guesses)
   procedure errors;

   --%test(add a guess)
   procedure add_guess;

   --%test(return all valid guesses)
   procedure valid_guesses;

   --%test(return all letters with pattern 1 or 2)
   procedure containing_letters;

   --%test(return all letters with pattern 0)
   procedure missing_letters;

   --%test(return aggregated like pattern)
   procedure like_pattern;

   --%test(return all not like patterns)
   procedure not_like_patterns;

   --%endcontext

   --%context(suggestions)

   --%test(return query to produce suggestions)
   procedure suggestions_query;

   --%test(return list of suggestions)
   procedure suggestions;

   --%endcontext
end test_game_ot;
/
