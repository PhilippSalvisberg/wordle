create or replace package body test_guess_ot is
   -- -----------------------------------------------------------------------------------------------------------------
   -- constructor_no_errors
   -- -----------------------------------------------------------------------------------------------------------------
   procedure constructor_no_errors is
      o_guess guess_ot;
   begin
      -- act
      o_guess := guess_ot('bobby', 'yabba', null, 0);
      
      -- assert
      ut.expect(o_guess.word).to_equal('bobby');
      ut.expect(o_guess.pattern).to_equal('00221');
      ut.expect(o_guess.errors.count).to_equal(0);
      ut.expect(o_guess.is_valid).to_equal(1);
   end constructor_no_errors;

   -- -----------------------------------------------------------------------------------------------------------------
   -- constructor_unknown_word
   -- -----------------------------------------------------------------------------------------------------------------
   procedure constructor_unknown_word is
      o_guess guess_ot;
   begin
      -- act
      o_guess := guess_ot('zzzzz', 'yabba', null, 0);
      
      -- assert
      ut.expect(o_guess.word).to_equal('zzzzz');
      ut.expect(o_guess.pattern).to_be_null;
      ut.expect(o_guess.errors.count).to_equal(1);
      ut.expect(o_guess.errors(1)).to_equal('zzzzz is not in word list.');
      ut.expect(o_guess.is_valid).to_equal(0);
   end constructor_unknown_word;

   -- -----------------------------------------------------------------------------------------------------------------
   -- constructor_short_word
   -- -----------------------------------------------------------------------------------------------------------------
   procedure constructor_short_word is
      o_guess guess_ot;
   begin
      -- act
      o_guess := guess_ot('zzzz', 'yabba', null, 0);
      
      -- assert
      ut.expect(o_guess.word).to_equal('zzzz');
      ut.expect(o_guess.pattern).to_be_null;
      ut.expect(o_guess.errors.count).to_equal(2);
      ut.expect(o_guess.errors(1)).to_equal('zzzz does not have exactly 5 letters.');
      ut.expect(o_guess.is_valid).to_equal(0);
   end constructor_short_word;

   -- -----------------------------------------------------------------------------------------------------------------
   -- constructor_long_word
   -- -----------------------------------------------------------------------------------------------------------------
   procedure constructor_long_word is
      o_guess guess_ot;
   begin
      -- act, throws a ORA-06502: PL/SQL: numeric or value error: character string buffer too small
      o_guess := guess_ot('zzzzzz', 'yabba', null, 0); -- NOSONAR: PL/SQL requires assignment
   end constructor_long_word;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- constructor_invalid_previous_guess
   -- -----------------------------------------------------------------------------------------------------------------
   procedure constructor_invalid_previous_guess is
      o_guess      guess_ot;
      o_prev_guess guess_ot;
   begin
      -- arange
      o_prev_guess := guess_ot('abcde', null, text_ct('some error'));
      
      -- act
      o_guess      := guess_ot('bobby', 'yabba', o_prev_guess, 1);
      
      -- assert
      ut.expect(o_guess.errors(1)).to_equal('valid previous guess of bobby is required in hard mode.');
   end constructor_invalid_previous_guess;

   -- -----------------------------------------------------------------------------------------------------------------
   -- constructor_hard_not_letter_x
   -- -----------------------------------------------------------------------------------------------------------------
   procedure constructor_hard_not_letter_x is
      o_guess      guess_ot;
      o_prev_guess guess_ot;
   begin
      -- arange
      o_prev_guess := guess_ot('bobby', 'yabba', null, 1);
      
      -- act
      o_guess      := guess_ot('comfy', 'yabba', o_prev_guess, 1);
      
      -- assert
      ut.expect(anydata.convertcollection(o_guess.errors)).to_equal(
         anydata.convertcollection(
            text_ct(
               'comfy''s letter #3 is not a B.',
               'comfy''s letter #4 is not a B.'
            )
         )
      ).unordered;
   end constructor_hard_not_letter_x;

   -- -----------------------------------------------------------------------------------------------------------------
   -- constructor_hard_missing_letter_x
   -- -----------------------------------------------------------------------------------------------------------------
   procedure constructor_hard_missing_letter_x is
      o_guess      guess_ot;
      o_prev_guess guess_ot;
   begin
      -- arange
      o_prev_guess := guess_ot('bobby', 'yabba', null, 1);
      
      -- act
      o_guess      := guess_ot('kibbi', 'yabba', o_prev_guess, 1);
      
      -- assert
      ut.expect(o_guess.errors(1)).to_equal('kibbi does not contain letter Y (1 times).');
   end constructor_hard_missing_letter_x;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- constructor_hard_no_errors
   -- -----------------------------------------------------------------------------------------------------------------
   procedure constructor_hard_no_errors is
      o_guess      guess_ot;
      o_prev_guess guess_ot;
   begin
      -- arange
      o_prev_guess := guess_ot('bobby', 'yabba', null, 1);
      
      -- act
      o_guess      := guess_ot('yobbo', 'yabba', o_prev_guess, 1);
      
      -- assert
      ut.expect(o_guess.is_valid).to_equal(1);
      ut.expect(o_guess.pattern).to_equal('20220');
   end constructor_hard_no_errors;

   -- -----------------------------------------------------------------------------------------------------------------
   -- containing_letters
   -- -----------------------------------------------------------------------------------------------------------------
   procedure containing_letters is
      o_guess    guess_ot;
      t_actual   text_ct;
      t_expected text_ct;
   begin
      -- arrange
      o_guess    := guess_ot('bobby', '00221', null);
      
      -- act
      t_actual   := o_guess.containing_letters;
      
      -- assert
      t_expected := text_ct('b', 'y');
      ut.expect(anydata.convertcollection(t_actual)).to_equal(anydata.convertcollection(t_expected)).unordered;
   end containing_letters;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- missing_letters
   -- -----------------------------------------------------------------------------------------------------------------
   procedure missing_letters is
      o_guess    guess_ot;
      t_actual   text_ct;
      t_expected text_ct;
   begin
      -- arrange
      o_guess    := guess_ot('bobby', '00221', null);
      
      -- act
      t_actual   := o_guess.missing_letters('yabba');
      
      -- assert
      t_expected := text_ct('o');
      ut.expect(anydata.convertcollection(t_actual)).to_equal(anydata.convertcollection(t_expected)).unordered;
   end missing_letters;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- like_pattern
   -- -----------------------------------------------------------------------------------------------------------------
   procedure like_pattern is
      o_guess  guess_ot;
      l_actual varchar2(5);
   begin
      -- arrange
      o_guess  := guess_ot('bobby', '00221', null);
      
      -- act
      l_actual := o_guess.like_pattern;
      
      -- assert
      ut.expect(l_actual).to_equal('__bb_');
   end like_pattern;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- not_like_patterns
   -- -----------------------------------------------------------------------------------------------------------------
   procedure not_like_patterns is
      o_guess    guess_ot;
      t_actual   text_ct;
      t_expected text_ct;
   begin
      -- arrange
      o_guess    := guess_ot('bobby', '10101', null);
      
      -- act
      t_actual   := o_guess.not_like_patterns;
      
      -- assert
      t_expected := text_ct('b____', '__b__', '____y');
      ut.expect(anydata.convertcollection(t_actual)).to_equal(anydata.convertcollection(t_expected));
   end not_like_patterns;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- not_like_pattern_successive_same_letters (see also issue #20)
   -- -----------------------------------------------------------------------------------------------------------------
   procedure not_like_pattern_successive_same_letters is
      o_guess    guess_ot;
      t_actual   text_ct;
      t_expected text_ct;
   begin
      -- arrange
      o_guess    := guess_ot('dully', 'pulpy', null, 1);
      
      -- act
      t_actual := o_guess.not_like_patterns('pulpy');
      
      -- assert
      t_expected := text_ct('___l_');
      ut.expect(anydata.convertcollection(t_actual)).to_equal(anydata.convertcollection(t_expected));
   end not_like_pattern_successive_same_letters;
end test_guess_ot;
/
