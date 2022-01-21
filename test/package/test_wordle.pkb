create or replace package body test_wordle is
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
      wordle.set_ansiconsole(false);
      wordle.set_show_query(false);
      
      -- act
      wordle.set_suggestions(1);

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
      wordle.set_ansiconsole(false);
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
select word
  from words
 where word like '__o_y'
   and word like '%r%'
   and word not like '%g%'
   and word not like '%l%'
   and word not in ('glory')
 order by case when game_number is not null then 0 else 1 end, word
 fetch first 2 rows only]'
           from dual
         union all
         select 'crony'
           from dual
         union all
         select 'irony'
           from dual;

      ut.expect(l_actual).to_equal(l_expected);
   end set_show_query;

   -- -----------------------------------------------------------------------------------------------------------------
   -- play_213_1
   -- -----------------------------------------------------------------------------------------------------------------
   procedure play_213_1 is
      l_actual   sys_refcursor;
      l_expected sys_refcursor;
   begin
      -- arrange
      wordle.set_ansiconsole(false);

      -- act
      open l_actual for select column_value from wordle.play(213, word_ct('noise')) where rownum = 1;
      
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
      -- arrange
      wordle.set_ansiconsole(false);

      -- act
      open l_actual for select column_value from wordle.play(213, word_ct('noise', 'jumbo')) where rownum < 3;
      
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
      -- arrange
      wordle.set_ansiconsole(false);

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
      -- arrange
      wordle.set_ansiconsole(false);

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
      -- arrange
      wordle.set_ansiconsole(false);

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

end test_wordle;
/