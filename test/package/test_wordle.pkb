create or replace package body test_wordle is

   -- -----------------------------------------------------------------------------------------------------------------
   -- reset_package_config
   -- -----------------------------------------------------------------------------------------------------------------
   procedure reset_package_config is
   begin
      wordle.set_ansiconsole(false);
      wordle.set_suggestions(10);
      wordle.set_show_query(true);
      wordle.set_hard_mode(false);
   end reset_package_config;

   -- -----------------------------------------------------------------------------------------------------------------
   -- set_ansiconsole
   -- -----------------------------------------------------------------------------------------------------------------
   procedure set_ansiconsole is
      l_actual varchar2(1000 byte);
   begin
      -- arrange
      wordle.set_ansiconsole(true);

      -- act
      select column_value into l_actual
        from wordle.play(213, 'noise')
       where rownum = 1;

      -- assert
      ut.expect(l_actual).to_be_like('%'
         || chr(27)
         || '%'
         || chr(27)
         || '%');
   end set_ansiconsole;

   -- -----------------------------------------------------------------------------------------------------------------
   -- set_suggestions
   -- -----------------------------------------------------------------------------------------------------------------
   procedure set_suggestions is
      l_actual   sys_refcursor;
      l_expected sys_refcursor;
   begin
      -- arrage
      wordle.set_show_query(false);
      
      -- act
      wordle.set_suggestions(2);

      -- assert
      open l_actual for select column_value from wordle.play(213, 'noise');
      open l_expected for
         select '-N- (O) -I- -S- -E-' as column_value
           from dual
         union all
         select null
           from dual
         union all
         select 'suggestions:'
           from dual
         union all
         select null
           from dual
         union all
         select 'ultra'
           from dual
         union all
         select 'abbot'
           from dual;
      ut.expect(l_actual).to_equal(l_expected);
   end set_suggestions;

   -- -----------------------------------------------------------------------------------------------------------------
   -- set_show_query
   -- -----------------------------------------------------------------------------------------------------------------
   procedure set_show_query is
      l_actual   sys_refcursor;
      l_expected sys_refcursor;
   begin
      -- arrange
      wordle.set_suggestions(2);
      
      -- act
      wordle.set_show_query(true);

      -- assert
      open l_actual for select column_value from wordle.play(213, 'glory');
      open l_expected for
         select '-G- -L- .O. (R) .Y.' as column_value
           from dual
         union all
         select q'[
with
   other_letters as (
      select w.word
        from words w
        join char_in_words cw
          on cw.word = w.word
        join chars c
          on c.character = cw.character
       where cw.character not in ('g','l','o','r','y')
       group by w.word
      having count(*) >= 4
       order by count(*) desc, sum(c.is_vowel) desc, sum(c.occurrences) desc, w.word
       fetch first 1 row only
   ),
   hard_mode as (
      select word
        from words
       where word like '__o_y'
         and instr(word, 'r', 1, 1) > 0
         and word not like '___r_'
         and word not like '%g%'
         and word not like '%l%'
         and word not in ('glory')
       order by case when game_number is not null then 0 else 1 end, word
       fetch first 2 rows only
   ),
   all_matcher as (
      select word
        from other_letters 
        union all 
      select word
        from hard_mode
   )
select word 
  from all_matcher
 fetch first 2 rows only]'
           from dual
         union all
         select 'adieu'
           from dual
         union all
         select 'crony'
           from dual;

      ut.expect(l_actual).to_equal(l_expected);
   end set_show_query;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- set_hard_mode
   -- -----------------------------------------------------------------------------------------------------------------
   procedure set_hard_mode is
      l_actual   sys_refcursor;
      l_expected sys_refcursor;
   begin
      -- act
      wordle.set_hard_mode(true);

      open l_actual for
         select text
           from (select rownum as row_num, column_value as text from wordle.play(201, 'abcde', 'annal', 'noise'))
          where row_num < 7
             or row_num = 8;

      open l_expected for
         select 'reduced input due to the following errors:' as text
           from dual
         union all
         select '- abcde is not in word list.'
           from dual
         union all
         select '- noise does not contain letter A (2 times).'
           from dual
         union all
         select '- noise''s letter #3 is not a N.'
           from dual
         union all
         select '- noise''s letter #4 is not a A.'
           from dual
         union all
         select '- noise''s letter #5 is not a L.'
           from dual
         union all
         select '(A) -N- .N. .A. .L.'
           from dual;
      ut.expect(l_actual).to_equal(l_expected);
   end set_hard_mode;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- play_213_1
   -- -----------------------------------------------------------------------------------------------------------------
   procedure play_213_1 is
      l_actual   sys_refcursor;
      l_expected sys_refcursor;
   begin
      -- act
      open l_actual for select column_value from wordle.play(213, text_ct('noise')) where rownum = 1;
      
      -- assert
      open l_expected for select '-N- (O) -I- -S- -E-' as column_value from dual;
      ut.expect(l_actual).to_equal(l_expected);
   end play_213_1;

   -- -----------------------------------------------------------------------------------------------------------------
   -- play_213_2
   -- -----------------------------------------------------------------------------------------------------------------
   procedure play_213_2 is
      l_actual   sys_refcursor;
      l_expected sys_refcursor;
   begin
      -- act
      open l_actual for select column_value from wordle.play(213, text_ct('noise', 'jumbo')) where rownum < 3;
      
      -- assert
      open l_expected for
         select '-N- (O) -I- -S- -E-' as column_value
           from dual
         union all
         select '-J- -U- -M- -B- (O)' as column_value
           from dual;
      ut.expect(l_actual).to_equal(l_expected);
   end play_213_2;

   -- -----------------------------------------------------------------------------------------------------------------
   -- play_213_3
   -- -----------------------------------------------------------------------------------------------------------------
   procedure play_213_3 is
      l_actual   sys_refcursor;
      l_expected sys_refcursor;
   begin
      -- act
      open l_actual for select column_value from wordle.play(213, 'noise', 'jumbo', 'octad') where rownum < 4;
      
      -- assert
      open l_expected for
         select '-N- (O) -I- -S- -E-' as column_value
           from dual
         union all
         select '-J- -U- -M- -B- (O)' as column_value
           from dual
         union all
         select '(O) -C- -T- -A- -D-' as column_value
           from dual;
      ut.expect(l_actual).to_equal(l_expected);
   end play_213_3;

   -- -----------------------------------------------------------------------------------------------------------------
   -- play_213_4
   -- -----------------------------------------------------------------------------------------------------------------
   procedure play_213_4 is
      l_actual   sys_refcursor;
      l_expected sys_refcursor;
   begin
      -- act
      open l_actual for select column_value from wordle.play(213, 'noise', 'jumbo', 'octad', 'glory') where rownum < 5;
      
      -- assert
      open l_expected for
         select '-N- (O) -I- -S- -E-' as column_value
           from dual
         union all
         select '-J- -U- -M- -B- (O)' as column_value
           from dual
         union all
         select '(O) -C- -T- -A- -D-' as column_value
           from dual
         union all
         select '-G- -L- .O. (R) .Y.' as column_value
           from dual;
      ut.expect(l_actual).to_equal(l_expected);
   end play_213_4;

   -- -----------------------------------------------------------------------------------------------------------------
   -- play_213_4
   -- -----------------------------------------------------------------------------------------------------------------
   procedure play_213_5 is
      l_actual   sys_refcursor;
      l_expected sys_refcursor;
   begin
      -- act
      open l_actual for select column_value from wordle.play(213, 'noise', 'jumbo', 'octad', 'glory', 'proxy');
      
      -- assert
      open l_expected for
         select '-N- (O) -I- -S- -E-' as column_value
           from dual
         union all
         select '-J- -U- -M- -B- (O)'
           from dual
         union all
         select '(O) -C- -T- -A- -D-'
           from dual
         union all
         select '-G- -L- .O. (R) .Y.'
           from dual
         union all
         select '.P. .R. .O. .X. .Y.'
           from dual
         union all
         select null
           from dual
         union all
         select 'Bravo! You completed Wordle 213 5/6' as column_value
           from dual;
      ut.expect(l_actual).to_equal(l_expected);
   end play_213_5;

   -- -----------------------------------------------------------------------------------------------------------------
   -- play_consider_wrong_positions_in_suggestions, see issue #2
   -- -----------------------------------------------------------------------------------------------------------------
   procedure play_consider_wrong_positions_in_suggestions is
      l_evaluation       varchar2(1000);
      l_first_suggestion varchar2(1000);
   begin
      -- arrange
      wordle.set_show_query(false);
      wordle.set_suggestions(1);
      
      -- act
      select column_value into l_evaluation from wordle.play(209, 'aback') where rownum = 1;
      select text
        into l_first_suggestion
        from (select rownum as row_num, column_value as text from wordle.play(209, 'aback'))
       where row_num = 5;
      
      -- assert guess
      ut.expect(l_evaluation).to_equal('(A) -B- -A- -C- -K-');

      -- assert suggestion
      -- cannot start with 'a', 'b', 'c' or 'k', hence it must not start with an 'a'.
      -- first suggestion was 'adage' before code change.
      ut.expect(l_first_suggestion).not_to_match('^a[a-z]{4}');
   end play_consider_wrong_positions_in_suggestions;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- play_number_of_letters_in_suggestions, see issue #6
   -- -----------------------------------------------------------------------------------------------------------------
   procedure play_consider_number_of_letters_in_suggestions is
      l_actual   sys_refcursor;
      l_expected sys_refcursor;
   begin
      -- arrange
      wordle.set_show_query(false);
      
      -- act
      open l_actual for
         select text
           from (select rownum as row_num, column_value as text from wordle.play(201, 'annal'))
          where row_num = 1
             or row_num between 5 and 7;
      
      -- assert suggestion, must contain two 'a'
      open l_expected for
         select '(A) -N- .N. .A. .L.' as text
           from dual
         union all
         select 'ourie'
           from dual
         union all
         select 'banal'
           from dual
         union all
         select 'canal'
           from dual;
      ut.expect(l_actual).to_equal(l_expected);
   end play_consider_number_of_letters_in_suggestions;

   -- -----------------------------------------------------------------------------------------------------------------
   -- play_consider_wrong_positions_in_suggestions_for_repeated_letters, see issue #8
   -- -----------------------------------------------------------------------------------------------------------------
   procedure play_consider_wrong_positions_in_suggestions_for_repeated_letters is
      l_evaluation       varchar2(1000);
      l_first_suggestion varchar2(1000);
   begin
      -- arrange
      wordle.set_show_query(false);
      wordle.set_suggestions(1);
      
      -- act
      select column_value into l_evaluation from wordle.play(162, 'aback') where rownum = 1;
      select text
        into l_first_suggestion
        from (select rownum as row_num, column_value as text from wordle.play(162, 'aback', 'defer', 'egret', 'inter'))
       where row_num = 8;
      
      -- assert guess
      ut.expect(l_evaluation).to_equal('-A- -B- -A- -C- -K-');

      -- assert suggestion
      -- cannot start with 'a', 'd', 'e' or 'i', hence it must not start with an 'e'.
      -- first suggestion was 'erupt' before code change.
      ut.expect(l_first_suggestion).not_to_match('^e[a-z]{4}');
   end play_consider_wrong_positions_in_suggestions_for_repeated_letters;
   
   -- -----------------------------------------------------------------------------------------------------------------
   -- play_consider_occurrences_of_repeated_letters, see issue #5
   -- -----------------------------------------------------------------------------------------------------------------
   procedure play_consider_occurrences_of_repeated_letters is
      l_actual varchar2(1000);
   begin
      -- act
      select text
        into l_actual
        from (select rownum as row_num, column_value as text from wordle.play(217, 'aback', 'cinch'))
       where row_num = 2;

      -- assert       
      ut.expect(l_actual).to_equal('-C- .I. .N. .C. -H-');
   end play_consider_occurrences_of_repeated_letters;

end test_wordle;
/
