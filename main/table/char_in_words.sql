create table char_in_words (
    character    varchar2(1 char) not null constraint chars_in_words_chars_fk references chars,
    word         varchar2(5 char) not null constraint chars_in_words_word_fk references words,
    occurrences  integer          not null,
                                  constraint char_in_words_pk primary key (character, word)
);
