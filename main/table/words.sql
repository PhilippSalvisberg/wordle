create table words (
   word             varchar2(5 char)   not null constraint words_pk primary key,
   distinct_letters integer default -1 not null,
   occurrences      integer default -1 not null,
   game_id          integer,
   game_date        date,
   constraint words_uk1 unique (game_id),
   constraint words_uk2 unique (game_date),
   constraint words_game_date_without_time_ck check (game_date = trunc(game_date)),
   constraint words_game_id_and_game_date_not_null_ck
     check (game_id is not null and game_date is not null
            or game_id is null and game_date is null)
);
