create or replace package test_guess_ot is
   --%suite(guess_ot)
   --%suitepath(wordle.internal)
   
   --%context(constructor)
   
   --%test(construct guess_ot without errors)
   procedure constructor_no_errors;
   
   --%test(construct guess_ot with error 'not in word list')
   procedure constructor_unknown_word;

   --%test(construct guess_ot with error 'not 5 letters')
   procedure constructor_short_word;

   --%test(cannot construct guess_ot with long guess)
   --%throws(-6502)
   procedure constructor_long_word;

   --%test(construct guess_ot with error 'valid previous guess required')
   procedure constructor_invalid_previous_guess;

   --%test(construct guess_ot with error 'is not letter X')
   procedure constructor_hard_not_letter_x;

   --%test(construct guess_ot with error 'does not contain letter X')
   procedure constructor_hard_missing_letter_x;

   --%test(construct guess_ot in hard mode without errors)
   procedure constructor_hard_no_errors;

   --%endcontext

   --%context(member)

   --%test(return all guessed letters, right and wrong possitions)
   procedure containing_letters;

   --%test(return all letters that that do not exist in the solution)
   procedure missing_letters;
   
   --%test(return like pattern for letters at the right position)
   procedure like_pattern;
   
   --%test(return a not like pattern for each letter at the wrong position)
   procedure not_like_patterns;
   
   --%test(return a not like patter for successive same letters)
   procedure not_like_pattern_successive_same_letters;

   --%endcontext
end test_guess_ot;
/
