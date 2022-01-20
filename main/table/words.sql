create table words (
    word         varchar2(5 char) not null constraint words_pk primary key,
    game_number  integer,
    game_on      date
);
