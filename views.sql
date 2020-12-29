drop view if exists view_songs;

drop view if exists view_home_songs;

drop view if exists view_user_songs;

drop view if exists count_user_songs;

drop view if exists count_user_playlists;

drop view if exists view_users;

create view view_songs as select 
	song_id as Id,
    if(get_admin_id(get_song_user_id(song_id)) > 0, 'YES', 'NO') as Admin,
    ifnull(get_playlist_name(get_playlist_id_by_song_id(song_id)), 'N/A') as Playlist,
    get_song_name(song_id) as Song,
    get_song_user_name(song_id) as User,
    get_song_artist_name(song_id) as Artist,
    get_song_genre(song_id) as Genre,
    get_song_description(song_id) as Description,
    get_song_downloads(song_id) as Download,
    get_song_listens(song_id) as Play
from songs
order by song_id desc;

create view view_home_songs as select 
	Id,
    Admin,
    Song,
    User,
    Artist,
    Genre,
    Playlist,
    Download,
    Play
from view_songs;

create view view_user_songs as select 
	User,
	Id,
    Song,
    Artist,
    Genre,
    Download,
    Play
from view_songs
where User = get_current_user_name();

create view count_user_songs as select
	user_name as User,
    count(*) as Songs 
from accounts left join songs 
on accounts.account_id = songs.user_id 
group by user_name;

create view count_user_playlists as select
	user_name as User,
    count(playlist_id) as Playlists
from accounts left join playlists 
on accounts.account_id = playlists.user_id 
group by user_name;

create view view_users as select 
	account_id as Id,
    user_name as User,
    password as Password,
    if(get_admin_id(account_id) > 0, 'YES', 'NO') as Admin,
    Songs,
    Playlists
from accounts, count_user_songs as s, count_user_playlists as p
where accounts.user_name = s.User and accounts.user_name = p.User
order by account_id desc;

