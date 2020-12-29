use narayanFall2020group1;

set foreign_key_checks = 0;

drop table if exists accounts;

drop table if exists admins;

drop table if exists artists;

drop table if exists contained;

drop table if exists genres;

drop table if exists messages;

drop table if exists playlists;

drop table if exists received;

drop table if exists sent;

drop table if exists songs;

drop table if exists song_details;

drop table if exists song_descriptions;

drop table if exists song_downloads;

drop table if exists song_listens;

drop table if exists logged_in;

drop table if exists cur_user;

drop table if exists search_home_songs;

drop table if exists order_home_songs;

drop table if exists search_user_songs;

drop table if exists order_user_songs;

drop table if exists search_accounts;

drop table if exists order_accounts;

drop table if exists manage_accounts;

drop table if exists manage_admins;

drop table if exists manage_artists;

drop table if exists manage_genres;

drop table if exists manage_messages;

drop table if exists manage_playlists;

drop table if exists manage_songs;

create table accounts (
    account_id int,
    user_name varchar(255) not null,
    password varchar(255) not null,
    primary key (account_id),
    unique key (user_name),
    index (user_name)
)  engine = INNODB;

create table admins (
    admin_id int,
    user_id int not null,
    primary key (admin_id),
    foreign key (user_id)
        references accounts (account_id)
        on delete cascade on update cascade,
	index (user_id)
)  engine = INNODB;

create table artists (
    artist_id int,
    artist_name varchar(255) not null,
    primary key (artist_id),
    unique key (artist_name),
    index (artist_name)
)  engine = INNODB;

create table genres (
    genre_id int,
    genre varchar(255) not null,
    primary key (genre_id),
    unique key (genre),
    index (genre)
)  engine = INNODB;

create table messages (
    message_id int,
    message varchar(255) not null,
    time_stamp datetime not null,
    primary key (message_id),
    index (message, time_stamp)
)  engine = INNODB;

create table playlists (
    playlist_id int,
    user_id int not null,
    playlist_name varchar(255) not null,
    primary key (playlist_id),
    foreign key (user_id)
        references accounts (account_id)
        on delete cascade on update cascade,
	index (user_id, playlist_name)
)  engine = INNODB;

create table received (
    message_id int,
    recipient_id int not null,
    primary key (message_id),
    foreign key (message_id)
        references messages (message_id)
        on delete cascade on update cascade,
    foreign key (recipient_id)
        references accounts (account_id)
        on delete cascade on update cascade,
	index (recipient_id)
)  engine = INNODB;

create table sent (
    message_id int,
    sender_id int not null,
    primary key (message_id),
    foreign key (message_id)
        references messages (message_id)
        on delete cascade on update cascade,
    foreign key (sender_id)
        references accounts (account_id)
        on delete cascade on update cascade,
	index (sender_id)
)  engine = INNODB;

create table songs (
    song_id int,
    user_id int not null,
    song_name varchar(255) not null,
    primary key (song_id),
    foreign key (user_id)
        references accounts (account_id)
        on delete cascade on update cascade,
	index (user_id, song_name)
)  engine = INNODB;

create table contained (
    playlist_id int not null,
    song_id int not null,
    foreign key (playlist_id)
        references playlists (playlist_id)
        on delete cascade on update cascade,
    foreign key (song_id)
        references songs (song_id)
        on delete cascade on update cascade,
	index (song_id)
)  engine = INNODB;

create table song_details (
    song_id int,
    artist_id int not null,
    genre_id int not null,
    primary key (song_id),
    foreign key (song_id)
        references songs (song_id)
        on delete cascade on update cascade,
    foreign key (artist_id)
        references artists (artist_id)
        on delete cascade on update cascade,
    foreign key (genre_id)
        references genres (genre_id)
        on delete cascade on update cascade,
	index (artist_id, genre_id)
)  engine = INNODB;

create table song_descriptions (
    song_id int,
    description varchar(255) not null,
    primary key (song_id),
    foreign key (song_id)
        references songs (song_id)
        on delete cascade on update cascade,
	index (description)
)  engine = INNODB;

create table song_downloads (
    song_id int,
    downloads int not null,
    primary key (song_id),
    foreign key (song_id)
        references songs (song_id)
        on delete cascade on update cascade,
	index (downloads)
)  engine = INNODB;

create table song_listens (
    song_id int,
    listens int not null,
    primary key (song_id),
    foreign key (song_id)
        references songs (song_id)
        on delete cascade on update cascade,
	index (listens)
)  engine = INNODB;

create table logged_in (
	user_id int default 0,
	primary key (user_id)
) engine = INNODB;

create table cur_user (
	user_id int default 0,
    primary key (user_id)
) engine = INNODB;

create table search_home_songs (
	user_id int,
	song varchar(255) not null default '',
    user varchar(255) not null default '',
    artist varchar(255) not null default '',
    genre varchar(255) not null default '',
    playlist varchar(255) not null default '',
    primary key (user_id)
) engine = INNODB;

create table order_home_songs (
	user_id int,
	song varchar(255) not null default '',
    user varchar(255) not null default '',
    artist varchar(255) not null default '',
    genre varchar(255) not null default '',
    playlist varchar(255) not null default '',
    download varchar(255) not null default '',
    play varchar(255) not null default '',
    primary key (user_id)
) engine = INNODB;

create table search_user_songs (
	user_id int,
	song varchar(255) not null default '',
    artist varchar(255) not null default '',
    genre varchar(255) not null default '',
    primary key (user_id)
) engine = INNODB;

create table order_user_songs (
	user_id int,
	song varchar(255) not null default '',
    artist varchar(255) not null default '',
    genre varchar(255) not null default '',
    download varchar(255) not null default '',
    play varchar(255) not null default '',
    primary key (user_id)
) engine = INNODB;

create table search_accounts (
	user_id int,
	user varchar(255) not null default '',
    admin varchar(255) not null default 'ALL',
    primary key (user_id)
) engine = INNODB;

create table order_accounts (
	user_id int,
	id varchar(255) not null default '',
    user varchar(255) not null default '',
    password varchar(255) not null default '',
    admin varchar(255) not null default '',
    songs varchar(255) not null default '',
    playlists varchar(255) not null default '',
    primary key (user_id)
) engine = INNODB;

create table manage_accounts (
    new_id int default 0,
    size int not null default 0,
    primary key (new_id)
) engine = INNODB;

create table manage_admins (
    new_id int default 0,
    size int not null default 0,
    primary key (new_id)
) engine = INNODB;

create table manage_artists (
    new_id int default 0,
    size int not null default 0,
    primary key (new_id)
) engine = INNODB;

create table manage_genres (
    new_id int default 0,
    size int not null default 0,
    primary key (new_id)
) engine = INNODB;

create table manage_messages (
    new_id int default 0,
    size int not null default 0,
    primary key (new_id)
) engine = INNODB;

create table manage_playlists (
    new_id int default 0,
    size int not null default 0,
    primary key (new_id)
) engine = INNODB;

create table manage_songs (
    new_id int default 0,
    size int not null default 0,
    primary key (new_id)
) engine = INNODB;

set foreign_key_checks = 1;

insert into manage_accounts values ();

insert into manage_admins values ();

insert into manage_artists values ();

insert into manage_genres values ();

insert into manage_messages values ();

insert into manage_playlists values ();

insert into manage_songs values ();

insert into logged_in values ();

insert into cur_user values ();

insert into search_home_songs values ();

insert into search_user_songs values ();

insert into search_accounts values ();

insert into order_home_songs values ();

insert into order_user_songs values ();

insert into order_accounts values ();


