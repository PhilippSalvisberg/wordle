create table words (
    word       varchar2(5 char) not null constraint words_pk primary key,
    game_id    integer,
    game_date  date,
                                constraint words_uk1 unique (game_id),
                                constraint words_uk2 unique (game_date)
);
