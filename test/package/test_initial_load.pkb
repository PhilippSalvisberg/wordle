create or replace package body test_initial_load is
   procedure load is
      c_actual   sys_refcursor;
      c_expected sys_refcursor;
   begin
      -- arrange
      delete from char_in_words;
      delete from words;
      delete from chars;
      
      -- act
      initial_load.load;
      
      -- assert chars
      open c_actual for select character, is_vowel from chars where character in ('a', 'z') order by character;
      open c_expected for select 'a' as character, 1 as is_vowel from dual union all select 'z', 0 from dual;
      ut.expect(c_actual).to_equal(c_expected);
      
      -- assert words
      open c_actual for select word, game_on from words where game_number = 212;
      open c_expected for select 'shire' as word, date '2022-01-17' as game_on from dual;
      ut.expect(c_actual).to_equal(c_expected);
      
      -- assert char_in_words
      open c_actual for
         select word, character, occurrences
           from char_in_words
          where word in ('shire', 'lolly');
      open c_expected for
         select 'lolly' as word, 'l' as character, 3 as occurrences
           from dual
         union all
         select 'lolly', 'o', 1
           from dual
         union all
         select 'lolly', 'y', 1
           from dual
         union all
         select 'shire', 's', 1
           from dual
         union all
         select 'shire', 'h', 1
           from dual
         union all
         select 'shire', 'i', 1
           from dual
         union all
         select 'shire', 'r', 1
           from dual
         union all
         select 'shire', 'e', 1
           from dual;
      ut.expect(c_actual).to_equal(c_expected).unordered;
   end load;

   procedure cleanup is
      l_actual integer;
   begin
      -- arrange
      delete from char_in_words;
      delete from words;
      delete from chars;
      initial_load.load;
      
      -- act
      initial_load.cleanup;
      
      -- assert chars
      select count(*) into l_actual from chars;
      ut.expect(l_actual).to_equal(0);

      -- assert words
      select count(*) into l_actual from words;
      ut.expect(l_actual).to_equal(0);
      
      -- assert char_in_words
      select count(*) into l_actual from char_in_words;
      ut.expect(l_actual).to_equal(0);
   end cleanup;

   procedure reload is
      l_actual                 integer;
      l_expected_chars         integer;
      l_expected_words         integer;
      l_expected_char_in_words integer;
   begin
      -- arrange
      delete from char_in_words;
      delete from words;
      delete from chars;
      initial_load.load;
      select count(*) into l_expected_chars from chars;
      select count(*) into l_expected_words from words;
      select count(*) into l_expected_char_in_words from char_in_words;
      delete from char_in_words
       where word in ('shire', 'lolly')
          or character = 'a';
      delete from words where word in ('shire', 'lolly');
      delete from chars where character = 'a';
      
      -- act
      initial_load.reload;
      
      -- assert chars
      ut.expect(l_expected_chars).to_be_greater_than(0);
      select count(*) into l_actual from chars;
      ut.expect(l_actual).to_equal(l_expected_chars);

      -- assert words
      ut.expect(l_expected_words).to_be_greater_than(0);
      select count(*) into l_actual from words;
      ut.expect(l_actual).to_equal(l_expected_words);
      
      -- assert char_in_words
      ut.expect(l_expected_char_in_words).to_be_greater_than(0);
      select count(*) into l_actual from char_in_words;
      ut.expect(l_actual).to_equal(l_expected_char_in_words);
   end reload;

end test_initial_load;
/
