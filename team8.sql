create table author
(
    author_id  int auto_increment
        primary key,
    first_name varchar(30) not null,
    last_name  varchar(30) not null
);

create table book
(
    book_id      int auto_increment
        primary key,
    title        varchar(150) not null,
    publisher    varchar(100) null,
    isbn         varchar(13)  null,
    publish_year int          null,
    constraint isbn
        unique (isbn)
);

create table copies
(
    copy_id      int auto_increment
        primary key,
    book_id      int                  not null,
    is_available tinyint(1) default 1 not null,
    constraint copies_ibfk_1
        foreign key (book_id) references team8.book (book_id)
);

create index book_id
    on copies (book_id);

create table staff
(
    staff_id   int auto_increment
        primary key,
    first_name varchar(30)  not null,
    last_name  varchar(30)  not null,
    email      varchar(100) not null,
    password   varchar(255) not null,
    is_admin   tinyint(1)   not null,
    constraint email
        unique (email)
);

create table user
(
    user_id    int auto_increment
        primary key,
    first_name varchar(30)  not null,
    last_name  varchar(30)  not null,
    email      varchar(100) not null,
    password   varchar(255) not null,
    is_faculty tinyint(1)   not null,
    constraint email
        unique (email)
);


