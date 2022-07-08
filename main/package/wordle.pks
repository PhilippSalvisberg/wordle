create or replace package wordle is
   procedure set_ansiconsole(in_ansiconsole in boolean default true);

   procedure set_suggestions(in_suggestions in integer default 10);

   procedure set_show_query(in_show_query in boolean default true);

   procedure set_hard_mode(in_hard_mode in boolean default true);

   function bulkplay(
      in_from_game_id in integer default null,
      in_to_game_id   in integer default null
   ) return xmltype;

   function play(
      in_game_id  in integer,
      in_words    in text_ct,
      in_autoplay in integer default 0
   ) return text_ct;

   function play(
      in_game_id in integer,
      in_word1   in varchar2,
      in_word2   in varchar2 default null,
      in_word3   in varchar2 default null,
      in_word4   in varchar2 default null,
      in_word5   in varchar2 default null,
      in_word6   in varchar2 default null
   ) return text_ct;

   function play(
      in_word1 in varchar2,
      in_word2 in varchar2 default null,
      in_word3 in varchar2 default null,
      in_word4 in varchar2 default null,
      in_word5 in varchar2 default null,
      in_word6 in varchar2 default null
   ) return text_ct;

   function autoplay(
      in_game_id in integer,
      in_word1   in varchar2 default null,
      in_word2   in varchar2 default null,
      in_word3   in varchar2 default null,
      in_word4   in varchar2 default null,
      in_word5   in varchar2 default null,
      in_word6   in varchar2 default null
   ) return text_ct;

   function autoplay(
      in_word1 in varchar2 default null,
      in_word2 in varchar2 default null,
      in_word3 in varchar2 default null,
      in_word4 in varchar2 default null,
      in_word5 in varchar2 default null,
      in_word6 in varchar2 default null
   ) return text_ct;
end wordle;
/
