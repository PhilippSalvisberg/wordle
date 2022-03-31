create or replace package body test_util is
   -- -----------------------------------------------------------------------------------------------------------------
   -- contains_entry
   -- -----------------------------------------------------------------------------------------------------------------
   procedure contains_entry is
      t_text   text_ct;
      l_actual boolean;
   begin
      -- arrange
      t_text   := text_ct('a', 'b', 'c');

      -- act
      l_actual := util.contains(in_text_ct => t_text, in_entry => 'b');
      
      -- assert
      ut.expect(l_actual).to_be_true();
   end contains_entry;

   -- -----------------------------------------------------------------------------------------------------------------
   -- missing_entry
   -- -----------------------------------------------------------------------------------------------------------------
   procedure missing_entry is
      t_text   text_ct;
      l_actual boolean;
   begin
      -- arrange
      t_text   := text_ct('a', 'b', 'c');

      -- act
      l_actual := util.contains(in_text_ct => t_text, in_entry => 'd');
      
      -- assert
      ut.expect(l_actual).to_be_false();
   end missing_entry;

   -- -----------------------------------------------------------------------------------------------------------------
   -- contains_null_entry
   -- -----------------------------------------------------------------------------------------------------------------
   procedure contains_null_entry is
      t_text   text_ct;
      l_actual boolean;
   begin
      -- arrange
      t_text   := text_ct('a', null, 'c');

      -- act
      l_actual := util.contains(in_text_ct => t_text, in_entry => 'd');
      
      -- assert
      -- one could argue that "true" is the correct result
      ut.expect(l_actual).to_be_false();
   end contains_null_entry;

   -- -----------------------------------------------------------------------------------------------------------------
   -- contains_null_entry_in_null_list
   -- -----------------------------------------------------------------------------------------------------------------
   procedure contains_null_entry_in_null_list is
      t_text   text_ct;
      l_actual boolean;
   begin
      -- act, throws ORA-06531: Reference to uninitialized collection
      l_actual := util.contains(in_text_ct => t_text, in_entry => null);
   end contains_null_entry_in_null_list;

   -- -----------------------------------------------------------------------------------------------------------------
   -- contains_null_entry_empty_list
   -- -----------------------------------------------------------------------------------------------------------------
   procedure contains_null_entry_empty_list is
      t_text   text_ct;
      l_actual boolean;
   begin
      -- arrange
      t_text   := text_ct();

      -- act
      l_actual := util.contains(in_text_ct => t_text, in_entry => 'a');
      
      -- assert
      ut.expect(l_actual).to_be_false();
   end contains_null_entry_empty_list;

   -- -----------------------------------------------------------------------------------------------------------------
   -- pattern_00000
   -- -----------------------------------------------------------------------------------------------------------------
   procedure pattern_00000 is
      l_actual varchar2(5 char);
   begin
      -- act
      l_actual := util.pattern(in_solution => 'abcde', in_guess => 'fghij');
      
      -- assert
      ut.expect(l_actual).to_equal('00000');
   end pattern_00000;

   -- -----------------------------------------------------------------------------------------------------------------
   -- pattern_11111
   -- -----------------------------------------------------------------------------------------------------------------
   procedure pattern_11111 is
      l_actual varchar2(5 char);
   begin
      -- act
      l_actual := util.pattern(in_solution => 'abcde', in_guess => 'bcdea');
      
      -- assert
      ut.expect(l_actual).to_equal('11111');
   end pattern_11111;

   -- -----------------------------------------------------------------------------------------------------------------
   -- pattern_22222
   -- -----------------------------------------------------------------------------------------------------------------
   procedure pattern_22222 is
      l_actual varchar2(5 char);
   begin
      -- act
      l_actual := util.pattern(in_solution => 'abcde', in_guess => 'abcde');
      
      -- assert
      ut.expect(l_actual).to_equal('22222');
   end pattern_22222;

   -- -----------------------------------------------------------------------------------------------------------------
   -- pattern_aaabb_abbcc
   -- -----------------------------------------------------------------------------------------------------------------
   procedure pattern_aaabb_abbcc is
      l_actual varchar2(5 char);
   begin
      -- act
      l_actual := util.pattern(in_solution => 'aaabb', in_guess => 'abbcc');
      
      -- assert
      ut.expect(l_actual).to_equal('21100');
   end pattern_aaabb_abbcc;

   -- -----------------------------------------------------------------------------------------------------------------
   -- pattern_wince_cinch (see #5) 
   -- -----------------------------------------------------------------------------------------------------------------
   procedure pattern_wince_cinch is
      l_actual varchar2(5 char);
   begin
      -- act
      l_actual := util.pattern(in_solution => 'wince', in_guess => 'cinch');
      
      -- assert
      ut.expect(l_actual).to_equal('02220');
   end pattern_wince_cinch;

   -- -----------------------------------------------------------------------------------------------------------------
   -- pattern_banal_annal (see #6)
   -- -----------------------------------------------------------------------------------------------------------------
   procedure pattern_banal_annal is
      l_actual varchar2(5 char);
   begin
      -- act
      l_actual := util.pattern(in_solution => 'banal', in_guess => 'annal');
      
      -- assert
      ut.expect(l_actual).to_equal('10222');
   end pattern_banal_annal;

   -- -----------------------------------------------------------------------------------------------------------------
   -- pattern_slosh_cross (see #24)
   -- -----------------------------------------------------------------------------------------------------------------
   procedure pattern_slosh_cross is
      l_actual varchar2(5 char);
   begin
      -- act
      l_actual := util.pattern(in_solution => 'slosh', in_guess => 'cross');
      
      -- assert
      ut.expect(l_actual).to_equal('00221');
   end pattern_slosh_cross;

   -- -----------------------------------------------------------------------------------------------------------------
   -- pattern_tangy_aback
   -- -----------------------------------------------------------------------------------------------------------------
   procedure pattern_tangy_aback is
      l_actual varchar2(5 char);
   begin
      -- act
      l_actual := util.pattern(in_solution => 'tangy', in_guess => 'aback');
      
      -- assert
      ut.expect(l_actual).to_equal('10000');
   end pattern_tangy_aback;

   -- -----------------------------------------------------------------------------------------------------------------
   -- encode_plain_text
   -- -----------------------------------------------------------------------------------------------------------------
   procedure encode_plain_text is
      l_actual varchar2(20);
   begin
      -- act
      l_actual := util.encode(in_word => 'abcde', in_pattern => '01210', in_ansiconsole => 0);

      -- assert
      ut.expect(l_actual).to_equal('-A- (B) .C. (D) -E-');
   end encode_plain_text;

   -- -----------------------------------------------------------------------------------------------------------------
   -- encode_ansiconsole
   -- -----------------------------------------------------------------------------------------------------------------
   procedure encode_ansiconsole is
      l_actual    varchar2(500);
      co_bg_green constant varchar2(30 char) := chr(27) || '[48;2;104;171;63m';
      co_bg_gold  constant varchar2(30 char) := chr(27) || '[48;2;198;181;94m';
      co_bg_gray  constant varchar2(30 char) := chr(27) || '[48;2;120;124;126m';
   begin
      -- act
      l_actual := util.encode(in_word => 'abcde', in_pattern => '21012', in_ansiconsole => 1);

      -- assert (2 green)
      ut.expect(instr(l_actual, co_bg_green, 1, 2)).to_be_greater_than(0);
      ut.expect(instr(l_actual, co_bg_green, 1, 3)).to_equal(0);
      
      -- assert (2 gold)
      ut.expect(instr(l_actual, co_bg_gold, 1, 2)).to_be_greater_than(0);
      ut.expect(instr(l_actual, co_bg_gold, 1, 3)).to_equal(0);
      
      -- assert (1 gray)
      ut.expect(instr(l_actual, co_bg_gray, 1, 1)).to_be_greater_than(0);
      ut.expect(instr(l_actual, co_bg_gray, 1, 2)).to_equal(0);
   end encode_ansiconsole;

   -- -----------------------------------------------------------------------------------------------------------------
   -- true_to_int
   -- -----------------------------------------------------------------------------------------------------------------
   procedure true_to_int is
      l_actual integer := 0;
   begin
      -- act
      l_actual := util.bool_to_int(true);
      
      -- assert
      ut.expect(l_actual).to_equal(1);
   end true_to_int;

   -- -----------------------------------------------------------------------------------------------------------------
   -- false_to_int
   -- -----------------------------------------------------------------------------------------------------------------
   procedure false_to_int is
      l_actual integer := 0;
   begin
      -- act
      l_actual := util.bool_to_int(false);
      
      -- assert
      ut.expect(l_actual).to_equal(0);
   end false_to_int;

   -- -----------------------------------------------------------------------------------------------------------------
   -- add_text_ct_non_existing
   -- -----------------------------------------------------------------------------------------------------------------
   procedure add_text_ct_non_existing is
      t_actual   text_ct := text_ct('a', 'b', 'c');
      t_expected text_ct := text_ct('a', 'b', 'c', 'd', 'e');
   begin
      -- act
      util.add_text_ct(io_text_ct => t_actual, in_text_ct => text_ct('d', 'e'));
      
      -- assert
      ut.expect(anydata.convertcollection(t_actual)).to_equal(anydata.convertcollection(t_expected));
   end add_text_ct_non_existing;

   -- -----------------------------------------------------------------------------------------------------------------
   -- add_text_ct_existing
   -- -----------------------------------------------------------------------------------------------------------------
   procedure add_text_ct_existing is
      t_actual   text_ct := text_ct('a', 'b', 'c');
      t_expected text_ct := text_ct('a', 'b', 'c', 'd');
   begin
      -- act
      util.add_text_ct(io_text_ct => t_actual, in_text_ct => text_ct('b', 'c', 'd'));
      
      -- assert
      ut.expect(anydata.convertcollection(t_actual)).to_equal(anydata.convertcollection(t_expected));
   end add_text_ct_existing;

   -- -----------------------------------------------------------------------------------------------------------------
   -- to_csv_some_string
   -- -----------------------------------------------------------------------------------------------------------------
   procedure to_csv_some_string is
      t_input text_ct := text_ct('a', 'b', 'c');
      l_actual varchar2(1000 char);
      l_expected varchar2(1000 char) := q'['a', 'b', 'c']';
   begin
      -- act
      l_actual := util.to_csv(t_input);
      
      -- assert
      ut.expect(l_actual).to_equal(l_expected);
   end to_csv_some_string;

   -- -----------------------------------------------------------------------------------------------------------------
   -- to_csv_null
   -- -----------------------------------------------------------------------------------------------------------------
   procedure to_csv_null is
      l_actual varchar2(1000 char);
   begin
      -- act, throws ORA-06531: Reference to uninitialized collection
      l_actual := util.to_csv(null);
   end to_csv_null;

   -- -----------------------------------------------------------------------------------------------------------------
   -- to_csv_empty
   -- -----------------------------------------------------------------------------------------------------------------
   procedure to_csv_empty is
      t_input text_ct := text_ct();
      l_actual varchar2(1000 char);
   begin
      -- act
      l_actual := util.to_csv(t_input);
      
      -- assert
      ut.expect(l_actual).to_be_null();
   end to_csv_empty;
end test_util;
/
