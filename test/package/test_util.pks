create or replace package test_util is
   --%suite(util)
   --%suitepath(wordle.internal)

   --%context(contains)

   --%test(contains entry)
   procedure contains_entry;

   --%test(missing entry)
   procedure missing_entry;

   --%test(contains null entry)
   procedure contains_null_entry;

   --%test(contains null entry in null list)
   --%throws(-6531)
   procedure contains_null_entry_in_null_list;
   
   --%test(contains null entry in empty list)
   procedure contains_null_entry_empty_list;

   --%endcontext

   --%context(pattern)

   --%test(Pattern 00000)
   procedure pattern_00000;
   
   --%test(Pattern 11111)
   procedure pattern_11111;

   --%test(Pattern 22222)
   procedure pattern_22222;
   
   --%test(Pattern of aaabb for abbcc)
   procedure pattern_aaabb_abbcc;

   --%test(Pattern of wince for cinch)
   procedure pattern_wince_cinch;

   --%test(Pattern of banal for annal)
   procedure pattern_banal_annal;
 
   --%test(Pattern of slosh for cross)
   procedure pattern_slosh_cross;

   --%test(Pattern of tangy for aback)
   procedure pattern_tangy_aback;

   --%endcontext

   --%context(encode)

   --%test(encode plain text)
   procedure encode_plain_text;
   
   --%test(encode ANSI console)
   procedure encode_ansiconsole;
   
   --%endcontext

   --%context(bool_to_int)

   --%test(true to int)
   procedure true_to_int;

   --%test(false to int)
   procedure false_to_int;

   --%endcontext

   --%context(add_text_ct)

   --%test(add non-existing entries to collection)
   procedure add_text_ct_non_existing;

   --%test(add existing entries to collection)
   procedure add_text_ct_existing;

   --%endcontext

   --%context(to_csv)

   --%test(convert some strings to csv)
   procedure to_csv_some_string;

   --%test(convert null to csv)
   --%throws(-6531)
   procedure to_csv_null;

   --%test(convert empty to csv)
   procedure to_csv_empty;

   --%endcontext
end test_util;
/
