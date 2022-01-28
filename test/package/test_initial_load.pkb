create or replace package body test_initial_load is
   procedure load is
      c_actual   sys_refcursor;
      c_expected sys_refcursor;
   begin
      -- arrange
      delete from letter_in_words;
      delete from words;
      delete from letters;
      
      -- act
      initial_load.load;
      
      -- assert chars
      open c_actual for select letter, is_vowel from letters where letter in ('a', 'z') order by letter;
      open c_expected for select 'a' as letter, 1 as is_vowel from dual union all select 'z', 0 from dual;
      ut.expect(c_actual).to_equal(c_expected);
      
      -- assert words
      open c_actual for select word, game_date from words where game_id = 212;
      open c_expected for select 'shire' as word, date '2022-01-17' as game_date from dual;
      ut.expect(c_actual).to_equal(c_expected);
      
      -- assert char_in_words
      open c_actual for
         select word, letter, occurrences
           from letter_in_words
          where word in ('shire', 'lolly');
      open c_expected for
         select 'lolly' as word, 'l' as letter, 3 as occurrences
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
      delete from letter_in_words;
      delete from words;
      delete from letters;
      initial_load.load;
      
      -- act
      initial_load.cleanup;
      
      -- assert chars
      select count(*) into l_actual from letters;
      ut.expect(l_actual).to_equal(0);

      -- assert words
      select count(*) into l_actual from words;
      ut.expect(l_actual).to_equal(0);
      
      -- assert char_in_words
      select count(*) into l_actual from letter_in_words;
      ut.expect(l_actual).to_equal(0);
   end cleanup;

   procedure reload is
      l_actual                 integer;
      l_expected_letters integer;
      l_expected_words         integer;
      l_expected_letter_in_words integer;
   begin
      -- arrange
      delete from letter_in_words;
      delete from words;
      delete from letters;
      initial_load.load;
      select count(*) into l_expected_letters from letters;
      select count(*) into l_expected_words from words;
      select count(*) into l_expected_letter_in_words from letter_in_words;
      delete from letter_in_words
       where word in ('shire', 'lolly')
          or letter = 'a';
      delete from words where word in ('shire', 'lolly');
      delete from letters where letter = 'a';
      
      -- act
      initial_load.reload;
      
      -- assert chars
      ut.expect(l_expected_letters).to_be_greater_than(0);
      select count(*) into l_actual from letters;
      ut.expect(l_actual).to_equal(l_expected_letters);

      -- assert words
      ut.expect(l_expected_words).to_be_greater_than(0);
      select count(*) into l_actual from words;
      ut.expect(l_actual).to_equal(l_expected_words);
      
      -- assert char_in_words
      ut.expect(l_expected_letter_in_words).to_be_greater_than(0);
      select count(*) into l_actual from letter_in_words;
      ut.expect(l_actual).to_equal(l_expected_letter_in_words);
   end reload;

end test_initial_load;
/
