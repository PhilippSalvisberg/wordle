create or replace package body test_game_ot is
   -- -----------------------------------------------------------------------------------------------------------------
   -- constructor_completed
   -- -----------------------------------------------------------------------------------------------------------------
   procedure constructor_completed is
      o_game game_ot;
   begin
      -- act
      o_game := game_ot('proxy', 1, text_ct('noise', 'jumbo', 'octad', 'glory', 'proxy'));
      
      -- assert
      ut.expect(o_game.is_initialized).to_equal(1);
      ut.expect(o_game.is_completed).to_equal(1);
   end constructor_completed;

   -- -----------------------------------------------------------------------------------------------------------------
   -- constructor_not_completed
   -- -----------------------------------------------------------------------------------------------------------------
   procedure constructor_not_completed is
      o_game game_ot;
   begin
      -- act
      o_game := game_ot('proxy', 1, text_ct('noise', 'jumbo', 'octad'));
      
      -- assert
      ut.expect(o_game.is_initialized).to_equal(1);
      ut.expect(o_game.is_completed).to_equal(0);
   end constructor_not_completed;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- errors
   -- -----------------------------------------------------------------------------------------------------------------
   procedure errors is
      o_game   game_ot;
      t_actual text_ct;
   begin
      -- arrange
      o_game   := game_ot('proxy', 1, text_ct('ab', 'noise', 'abcde', 'jumbo', 'octad'));

      -- act
      t_actual := o_game.errors;
      
      -- assert
      ut.expect(anydata.convertcollection(t_actual)).to_equal(
         anydata.convertcollection(
            text_ct(
               'ab does not have exactly 5 letters.',
               'ab is not in word list.',
               'abcde is not in word list.',
               'abcde does not contain letter O (1 times).'
            )
         )
      ).unordered;
   end errors;

   -- -----------------------------------------------------------------------------------------------------------------
   -- add_guess
   -- -----------------------------------------------------------------------------------------------------------------
   procedure add_guess is
      o_game game_ot;
   begin
      -- arrange
      o_game := game_ot('proxy', 1, text_ct('noise', 'jumbo', 'octad'));

      -- act
      o_game.add_guess('glory');
      
      -- assert
      ut.expect(o_game.valid_guesses()(4).word).to_equal('glory');
   end add_guess;

   -- -----------------------------------------------------------------------------------------------------------------
   -- valid_guesses
   -- -----------------------------------------------------------------------------------------------------------------
   procedure valid_guesses is
      o_game   game_ot;
      t_actual guess_ct;
   begin
      -- arrange
      o_game   := game_ot('proxy', 1, text_ct('yyyyy', 'noise', 'abc', 'def', 'jumbo', 'lyart', 'octad'));
      
      -- act
      t_actual := o_game.valid_guesses;

      -- assert
      ut.expect(t_actual.count).to_equal(3);
      ut.expect(t_actual(1).word).to_equal('noise');
      ut.expect(t_actual(2).word).to_equal('jumbo');
      ut.expect(t_actual(3).word).to_equal('octad');
   end valid_guesses;

   -- -----------------------------------------------------------------------------------------------------------------
   -- containing_letters
   -- -----------------------------------------------------------------------------------------------------------------
   procedure containing_letters is
      o_game   game_ot;
      t_actual text_ct;
   begin
      -- arrange
      o_game   := game_ot('proxy', 1, text_ct('noise', 'jumbo'));

      -- act
      t_actual := o_game.containing_letters;
      
      -- assert
      ut.expect(anydata.convertcollection(t_actual)).to_equal(anydata.convertcollection(text_ct('o'))).unordered;
   end containing_letters;

   -- -----------------------------------------------------------------------------------------------------------------
   -- missing_letters
   -- -----------------------------------------------------------------------------------------------------------------
   procedure missing_letters is
      o_game   game_ot;
      t_actual text_ct;
   begin
      -- arrange
      o_game   := game_ot('proxy', 1, text_ct('noise', 'jumbo'));

      -- act
      t_actual := o_game.missing_letters;

      -- assert
      ut.expect(anydata.convertcollection(t_actual)).to_equal(
         anydata.convertcollection(
            text_ct('n', 'i', 's', 'e', 'j', 'u', 'm', 'b')
         )
      ).unordered;
   end missing_letters;

   -- -----------------------------------------------------------------------------------------------------------------
   -- like_pattern
   -- -----------------------------------------------------------------------------------------------------------------
   procedure like_pattern is
      o_game   game_ot;
      l_actual varchar2(5);
   begin
      -- arrange
      o_game   := game_ot('proxy', 1, text_ct('noise', 'jumbo', 'octad', 'glory'));
      
      -- act
      l_actual := o_game.like_pattern;
      
      -- assert
      ut.expect(l_actual).to_equal('__o_y');
   end like_pattern;

   -- -----------------------------------------------------------------------------------------------------------------
   -- not_like_patterns
   -- -----------------------------------------------------------------------------------------------------------------
   procedure not_like_patterns is
      o_game   game_ot;
      t_actual text_ct;
   begin
      -- arrange
      o_game   := game_ot('proxy', 1, text_ct('noise', 'jumbo', 'octad', 'glory'));

      -- act
      t_actual := o_game.not_like_patterns;
      
      -- assert
      ut.expect(anydata.convertcollection(t_actual)).to_equal(
         anydata.convertcollection(
            text_ct('_o___', '____o', 'o____', '___r_')
         )
      ).unordered;
   end not_like_patterns;

   -- -----------------------------------------------------------------------------------------------------------------
   -- suggestions_query
   -- -----------------------------------------------------------------------------------------------------------------
   procedure suggestions_query is
      o_game   game_ot;
      l_actual varchar2(4000);
   begin
      -- arrange
      o_game   := game_ot('proxy', 1, text_ct('noise'));
      
      -- act
      l_actual := o_game.suggestions_query;

      -- assert
      ut.expect(l_actual).to_match('^with.*select word.*fetch first 10 rows only$', 'n');
   end suggestions_query;

   -- -----------------------------------------------------------------------------------------------------------------
   -- suggestions
   -- -----------------------------------------------------------------------------------------------------------------
   procedure suggestions is
      o_game   game_ot;
      t_actual text_ct;
   begin
      -- arrange
      o_game   := game_ot('proxy', 1, text_ct('noise', 'jumbo', 'octad', 'glory'));
      
      -- act
      t_actual := o_game.suggestions;
      
      -- assert
      ut.expect(anydata.convertcollection(t_actual)).to_equal(
         anydata.convertcollection(text_ct('proxy', 'frowy'))
      ).unordered;
   end suggestions;
end test_game_ot;
/