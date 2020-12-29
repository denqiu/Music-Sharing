use narayanFall2020group1;

drop function if exists get_user_id;

drop function if exists get_user_name;

drop function if exists get_user_password;

drop function if exists get_admin_id;

drop function if exists get_admin_user_id;

drop function if exists get_admin_name;

drop function if exists get_artist_id;

drop function if exists get_artist_name;

drop function if exists get_genre_id;

drop function if exists get_genre;

drop function if exists get_message_id;

drop function if exists get_message_date;

drop function if exists get_message_text;

drop function if exists get_sender_id;

drop function if exists get_sender_name;

drop function if exists get_recipient_id;

drop function if exists get_recipient_name;

drop function if exists get_playlist_id;

drop function if exists get_playlist_id_by_song_id;

drop function if exists get_playlist_name;

drop function if exists get_playlist_user_id;

drop function if exists get_playlist_user_name;

drop function if exists get_song_id;

drop function if exists get_song_name;

drop function if exists get_song_user_id;

drop function if exists get_song_user_name;

drop function if exists get_song_description;

drop function if exists get_song_artist_id;

drop function if exists get_song_artist_name;

drop function if exists get_song_genre_id;

drop function if exists get_song_genre;

drop function if exists get_song_downloads;

drop function if exists get_song_listens;

drop function if exists get_user_id_logged_in;

drop function if exists get_user_name_logged_in;

drop function if exists get_current_user_id;

drop function if exists get_current_user_name;

drop function if exists get_search_home_id;

drop function if exists get_search_home_song;

drop function if exists get_search_home_user;

drop function if exists get_search_home_artist;

drop function if exists get_search_home_genre;

drop function if exists get_search_home_playlist;

drop function if exists get_order_home_id;

drop function if exists get_home_order_song;
    
drop function if exists get_home_order_user;
    
drop function if exists get_home_order_artist;
    
drop function if exists get_home_order_genre;
    
drop function if exists get_home_order_playlist;
    
drop function if exists get_home_order_download;
    
drop function if exists get_home_order_play;

drop function if exists get_search_user_id;

drop function if exists get_search_user_song;

drop function if exists get_search_user_artist;

drop function if exists get_search_user_genre;

drop function if exists get_order_user_id;

drop function if exists get_user_order_song;

drop function if exists get_user_order_artist;

drop function if exists get_user_order_genre;

drop function if exists get_user_order_download;
   
drop function if exists get_user_order_play;

drop function if exists get_search_accounts_id;

drop function if exists get_search_accounts_user;

drop function if exists get_search_accounts_admin;

drop function if exists get_order_accounts_id;

drop function if exists get_accounts_order_id;

drop function if exists get_accounts_order_user;

drop function if exists get_accounts_order_password;

drop function if exists get_accounts_order_admin;
    
drop function if exists get_accounts_order_songs;

drop function if exists get_accounts_order_playlists;

delimiter $$

create function get_user_id(u_name varchar(255)) returns int
	begin
		return ifnull((select account_id from accounts where user_name = u_name), 0);
    end $$
    
create function get_user_name(u_id int) returns varchar(255)
	begin
        return (select user_name from accounts where account_id = u_id);
    end $$
    
create function get_user_password(u_name varchar(255)) returns varchar(255)
	begin
        return (select password from accounts where user_name = u_name);
    end $$
    
create function get_admin_id(u_id int) returns int
	begin
        return ifnull((select admin_id from admins where user_id = u_id), 0);
    end $$
    
create function get_admin_user_id(a_id int) returns int
	begin
        return ifnull((select user_id from admins where admin_id = a_id), 0);
    end $$
    
create function get_admin_name(a_id int) returns varchar(255)
	begin        
        return get_user_name(get_admin_user_id(a_id));
    end $$
    
create function get_artist_id(a_name varchar(255)) returns int
	begin
		return ifnull((select artist_id from artists where artist_name = a_name), 0);
    end $$
    
create function get_artist_name(a_id int) returns varchar(255)
	begin
        return (select artist_name from artists where artist_id = a_id);
    end $$
    
create function get_genre_id(g_name varchar(255)) returns int
	begin
		return ifnull((select genre_id from genres where genre = g_name), 0);
    end $$
       
create function get_genre(g_id int) returns varchar(255)
	begin
        return (select genre from genres where genre_id = g_id);
    end $$
    
create function get_message_id(m_date datetime) returns int
	begin
        return ifnull((select message_id from messages where time_stamp = m_date), 0);
    end $$
      
create function get_message_date(m_id int) returns datetime
	begin
        return (select time_stamp from messages where message_id = m_id);
    end $$
    
create function get_message_text(m_id int) returns varchar(255)
	begin
        return (select message from messages where message_id = m_id);
    end $$
    
create function get_sender_id(m_id int) returns int
	begin
        return ifnull((select sender_id from sent where message_id = m_id), 0);
    end $$
    
create function get_sender_name(m_id int) returns varchar(255)
	begin
		return get_user_name(get_sender_id(m_id));
    end $$
        
create function get_recipient_id(m_id int) returns int
	begin
        return ifnull((select recipient_id from received where message_id = m_id), 0);
    end $$
    
create function get_recipient_name(m_id int) returns varchar(255)
	begin
		return get_user_name(get_recipient_id(m_id));
    end $$
        
create function get_playlist_id(u_id int, p_name varchar(255)) returns int
	begin
        return ifnull((select playlist_id from playlists where user_id = u_id and playlist_name = p_name), 0);
    end $$
    
create function get_playlist_id_by_song_id(s_id int) returns int
	begin
        return ifnull((select playlist_id from contained where song_id = s_id), 0);
    end $$
    
create function get_playlist_name(p_id int) returns varchar(255)
	begin
        return (select playlist_name from playlists where playlist_id = p_id);
    end $$
    
create function get_playlist_user_id(p_id int) returns int
	begin
        return (select user_id from playlists where playlist_id = p_id);
    end $$
    
create function get_playlist_user_name(p_id int) returns varchar(255)
	begin
		return get_user_name(get_playlist_user_id(p_id));
    end $$
    
create function get_song_id(u_id int, s_name varchar(255)) returns int
	begin
        return ifnull((select song_id from songs where user_id = u_id and song_name = s_name), 0);
    end $$
  
create function get_song_name(s_id int) returns varchar(255)
	begin
        return (select song_name from songs where song_id = s_id);
    end $$
    
create function get_song_user_id(s_id int) returns int
	begin
        return (select user_id from songs where song_id = s_id);
    end $$
    
create function get_song_user_name(s_id int) returns varchar(255)
	begin
		return get_user_name(get_song_user_id(s_id));
	end $$
       
create function get_song_description(s_id int) returns varchar(255)
	begin
        return (select description from song_descriptions where song_id = s_id);
    end $$
          
create function get_song_artist_id(s_id int) returns int
	begin
        return (select artist_id from song_details where song_id = s_id);
    end $$
    
create function get_song_artist_name(s_id int) returns varchar(255)
	begin
		return get_artist_name(get_song_artist_id(s_id));
	end $$
     
create function get_song_genre_id(s_id int) returns int
	begin
        return (select genre_id from song_details where song_id = s_id);
    end $$
    
create function get_song_genre(s_id int) returns varchar(255)
	begin
		return get_genre(get_song_genre_id(s_id));
	end $$
     
create function get_song_downloads(s_id int) returns int
	begin 
		return ifnull((select downloads from song_downloads where song_id = s_id), 0);
    end $$
    
create function get_song_listens(s_id int) returns int
	begin 
		return ifnull((select listens from song_listens where song_id = s_id), 0);
    end $$

create function get_user_id_logged_in() returns int
	begin
		return ifnull((select user_id from logged_in), 0);
    end $$
    
create function get_user_name_logged_in() returns varchar(255)
	begin
		return get_user_name(get_user_id_logged_in());
	end $$
    
create function get_current_user_id() returns int
	begin
		return ifnull((select user_id from cur_user), 0);
    end $$
    
create function get_current_user_name() returns varchar(255)
	begin
		return get_user_name(get_current_user_id());
	end $$
    
create function get_search_home_id() returns int 
	begin
		return ifnull((select user_id from search_home_songs where user_id = get_user_id_logged_in()), 0);
    end $$
    
create function get_search_home_song() returns varchar(255)
	begin 
		return (select song from search_home_songs where user_id = get_user_id_logged_in());
    end $$

create function get_search_home_user() returns varchar(255)
	begin 
		return (select user from search_home_songs where user_id = get_user_id_logged_in());
    end $$

create function get_search_home_artist() returns varchar(255)
	begin 
		return (select artist from search_home_songs where user_id = get_user_id_logged_in());
    end $$

create function get_search_home_genre() returns varchar(255)
	begin 
		return (select genre from search_home_songs where user_id = get_user_id_logged_in());
    end $$

create function get_search_home_playlist() returns varchar(255)
	begin 
		return (select playlist from search_home_songs where user_id = get_user_id_logged_in());
    end $$
    
create function get_order_home_id() returns int
	begin
		return ifnull((select user_id from order_home_songs where user_id = get_user_id_logged_in()), 0);
    end $$
    
create function get_home_order_song() returns varchar(255)
	begin
		return (select song from order_home_songs where user_id = get_user_id_logged_in());
    end $$
    
create function get_home_order_user() returns varchar(255)
	begin
		return (select user from order_home_songs where user_id = get_user_id_logged_in());
    end $$
    
create function get_home_order_artist() returns varchar(255)
	begin
		return (select artist from order_home_songs where user_id = get_user_id_logged_in());
    end $$
    
create function get_home_order_genre() returns varchar(255)
	begin
		return (select genre from order_home_songs where user_id = get_user_id_logged_in());
    end $$
    
create function get_home_order_playlist() returns varchar(255)
	begin
		return (select playlist from order_home_songs where user_id = get_user_id_logged_in());
    end $$
    
create function get_home_order_download() returns varchar(255)
	begin
		return (select download from order_home_songs where user_id = get_user_id_logged_in());
    end $$
    
create function get_home_order_play() returns varchar(255)
	begin
		return (select play from order_home_songs where user_id = get_user_id_logged_in());
    end $$

create function get_search_user_id() returns int 
	begin
		return ifnull((select user_id from search_user_songs where user_id = get_user_id_logged_in()), 0);
    end $$
    
create function get_search_user_song() returns varchar(255)
	begin 
		return (select song from search_user_songs where user_id = get_user_id_logged_in());
    end $$

create function get_search_user_artist() returns varchar(255)
	begin 
		return (select artist from search_user_songs where user_id = get_user_id_logged_in());
    end $$

create function get_search_user_genre() returns varchar(255)
	begin 
		return (select genre from search_user_songs where user_id = get_user_id_logged_in());
    end $$
    
create function get_order_user_id() returns int
	begin
		return ifnull((select user_id from order_user_songs where user_id = get_user_id_logged_in()), 0);
    end $$
    
create function get_user_order_song() returns varchar(255)
	begin
		return (select song from order_user_songs where user_id = get_user_id_logged_in());
    end $$
    
create function get_user_order_artist() returns varchar(255)
	begin
		return (select artist from order_user_songs where user_id = get_user_id_logged_in());
    end $$
    
create function get_user_order_genre() returns varchar(255)
	begin
		return (select genre from order_user_songs where user_id = get_user_id_logged_in());
    end $$
    
create function get_user_order_download() returns varchar(255)
	begin
		return (select download from order_user_songs where user_id = get_user_id_logged_in());
    end $$
    
create function get_user_order_play() returns varchar(255)
	begin
		return (select play from order_user_songs where user_id = get_user_id_logged_in());
    end $$
    
create function get_search_accounts_id() returns int 
	begin
		return ifnull((select user_id from search_accounts where user_id = get_user_id_logged_in()), 0);
    end $$
    
create function get_search_accounts_user() returns varchar(255)
	begin 
		return (select user from search_accounts where user_id = get_user_id_logged_in());
    end $$

create function get_search_accounts_admin() returns varchar(255)
	begin 
		return (select admin from search_accounts where user_id = get_user_id_logged_in());
    end $$
    
create function get_order_accounts_id() returns int
	begin
		return ifnull((select user_id from order_accounts where user_id = get_user_id_logged_in()), 0);
    end $$
    
create function get_accounts_order_id() returns varchar(255)
	begin
		return (select id from order_accounts where user_id = get_user_id_logged_in());
    end $$
    
create function get_accounts_order_user() returns varchar(255)
	begin
		return (select user from order_accounts where user_id = get_user_id_logged_in());
    end $$
    
create function get_accounts_order_password() returns varchar(255)
	begin
		return (select password from order_accounts where user_id = get_user_id_logged_in());
    end $$
    
create function get_accounts_order_songs() returns varchar(255)
	begin
		return (select songs from order_accounts where user_id = get_user_id_logged_in());
    end $$
    
create function get_accounts_order_playlists() returns varchar(255)
	begin
		return (select playlists from order_accounts where user_id = get_user_id_logged_in());
    end $$
    
delimiter ;