use narayanFall2020group1;

drop procedure if exists set_error;

drop function if exists is_empty;

drop procedure if exists check_empty;

drop function if exists manage_account_id;

drop function if exists manage_admin_id;

drop function if exists manage_artist_id;

drop function if exists manage_genre_id;

drop function if exists manage_message_id;

drop function if exists manage_playlist_id;

drop function if exists manage_song_id;

drop function if exists manage_account_size;

drop function if exists manage_admin_size;

drop function if exists manage_artist_size;

drop function if exists manage_genre_size;

drop function if exists manage_message_size;

drop function if exists manage_playlist_size;

drop function if exists manage_song_size;

drop procedure if exists password_conditions;

drop trigger if exists check_account;

drop trigger if exists check_account_update;

drop trigger if exists check_admin;

drop trigger if exists check_artist;

drop trigger if exists check_genre;

drop trigger if exists update_message_date;

drop trigger if exists check_message;

drop trigger if exists check_playlist;

drop trigger if exists check_song;

drop trigger if exists check_search_home;

drop trigger if exists check_order_home;

drop trigger if exists check_search_user;

drop trigger if exists check_order_user;

drop trigger if exists check_search_accounts;

drop trigger if exists check_order_accounts;

drop trigger if exists del_account;

drop trigger if exists del_admin;

drop trigger if exists del_artist;

drop trigger if exists del_genre;

drop trigger if exists del_message;

drop trigger if exists del_playlist;

drop trigger if exists del_song;

delimiter $$

create procedure set_error(in msg varchar(255))
	begin
		signal sqlstate '45000' set message_text = msg;
    end $$
    
create function is_empty(str varchar(255)) returns boolean
	begin
		return trim(str) = '' or str is null;
	end $$

create procedure check_empty(in field_name varchar(255), in field_value varchar(255))
	begin
		declare cap varchar(255);
        declare name varchar(255);
        if is_empty(field_value) then
			set name = replace(field_name, '_', ' ');
			set cap = concat(ucase(left(name, 1)), substring(name, 2));
			call set_error(concat(cap, ' cannot be empty. Please create a ', name, '.'));
        end if;
    end $$
       
create function manage_account_id() returns int
	begin
		return (select new_id from manage_accounts);
	end $$
       
create function manage_admin_id() returns int
	begin
		return (select new_id from manage_admins);
	end $$
    
create function manage_artist_id() returns int
	begin
		return (select new_id from manage_artists);
    end $$
    
create function manage_genre_id() returns int
	begin
		return (select new_id from manage_genres);
	end $$
    
create function manage_message_id() returns int
	begin 
		return (select new_id from manage_messages);
	end $$
    
create function manage_playlist_id() returns int
	begin
		return (select new_id from manage_playlists);
	end $$
    
create function manage_song_id() returns int
	begin
		return (select new_id from manage_songs);
	end $$
    
create function manage_account_size() returns int
	begin
		return (select size from manage_accounts);
	end $$
       
create function manage_admin_size() returns int
	begin
		return (select size from manage_admins);
	end $$
    
create function manage_artist_size() returns int
	begin
		return (select size from manage_artists);
    end $$
    
create function manage_genre_size() returns int
	begin
		return (select size from manage_genres);
	end $$
    
create function manage_message_size() returns int
	begin 
		return (select size from manage_messages);
	end $$
    
create function manage_playlist_size() returns int
	begin
		return (select size from manage_playlists);
	end $$
    
create function manage_song_size() returns int
	begin
		return (select size from manage_songs);
	end $$
    
create procedure password_conditions(in pass varchar(255))
	begin
		set @low = binary pass regexp '[a-z]';
        set @up = binary pass regexp '[A-Z]';
        set @num = pass regexp '[0-9]';
		if not (@low and @up and @num) then
			call set_error('Password must contain upper and lower case letters and numbers.');
		end if;
    end $$
    
create trigger check_account before insert on accounts for each row
	begin
		call check_empty('user_name', new.user_name);
		call check_empty('password', new.password);
		call password_conditions(new.password);
		update manage_accounts set new_id = manage_account_id() + 1, size = manage_account_size() + 1;
		set new.account_id = manage_account_id();
	end $$
    
create trigger check_account_update before update on accounts for each row
	begin
		if old.user_name = new.user_name then
			call check_empty('password', new.password);
			if binary old.password = new.password then
				call set_error('This password is already in use. Please create a new password.');
			end if;
			call password_conditions(new.password);
		else
			call check_empty('user_name', new.user_name);
        end if;
    end $$
    
create trigger check_admin before insert on admins for each row
	begin
		update manage_admins set new_id = manage_admin_id() + 1, size = manage_admin_size() + 1;
		set new.admin_id = manage_admin_id();
	end $$
    
create trigger check_artist before insert on artists for each row
	begin
		call check_empty('artist_name', new.artist_name);
		update manage_artists set new_id = manage_artist_id() + 1, size = manage_artist_size() + 1;
		set new.artist_id = manage_artist_id();
	end $$
    
create trigger check_genre before insert on genres for each row
	begin
		call check_empty('genre', new.genre);
		update manage_genres set new_id = manage_genre_id() + 1, size = manage_genre_size() + 1;
		set new.genre_id = manage_genre_id();
	end $$
    
create trigger update_message_date before update on messages for each row
	begin
		set new.time_stamp = now();
    end $$
    
create trigger check_message before insert on messages for each row
	begin
		update manage_messages set new_id = manage_message_id() + 1, size = manage_message_size() + 1;
		set new.message_id = manage_message_id();
        set new.time_stamp = now();
	end $$
    
create trigger check_sent before insert on sent for each row
	begin
		set new.message_id = manage_message_id();
    end $$
    
create trigger check_received before insert on received for each row
	begin
		set new.message_id = manage_message_id();
    end $$

create trigger check_playlist before insert on playlists for each row
	begin
		call check_empty('playlist_name', new.playlist_name);
		update manage_playlists set new_id = manage_playlist_id() + 1, size = manage_playlist_size() + 1;
		set new.playlist_id = manage_playlist_id();
	end $$

create trigger check_song before insert on songs for each row
	begin
		call check_empty('song_name', new.song_name);
		update manage_songs set new_id = manage_song_id() + 1, size = manage_song_size() + 1;
		set new.song_id = manage_song_id();
	end $$

create trigger check_search_home before insert on search_home_songs for each row
	begin
		set new.user_id = get_user_id_logged_in();
	end $$

create trigger check_order_home before insert on order_home_songs for each row
	begin
		set new.user_id = get_user_id_logged_in();
	end $$

create trigger check_search_user before insert on search_user_songs for each row
	begin
		set new.user_id = get_user_id_logged_in();
	end $$

create trigger check_order_user before insert on order_user_songs for each row
	begin
		set new.user_id = get_user_id_logged_in();
	end $$

create trigger check_search_accounts before insert on search_accounts for each row
	begin
		set new.user_id = get_user_id_logged_in();
	end $$

create trigger check_order_accounts before insert on order_accounts for each row
	begin
		set new.user_id = get_user_id_logged_in();
	end $$

create trigger del_account before delete on accounts for each row
	begin
		update manage_accounts set size = manage_account_size() - 1;
	end $$

create trigger del_admin before delete on admins for each row
	begin
		update manage_admins set size = manage_admin_size() - 1;
	end $$
    
create trigger del_artist before delete on artists for each row
	begin
		update manage_artists set size = manage_artist_size() - 1;
	end $$
    
create trigger del_genre before delete on genres for each row
	begin
		update manage_genres set size = manage_genre_size() - 1;
	end $$
    
create trigger del_message before delete on messages for each row
	begin
		update manage_messages set size = manage_message_size() - 1;
	end $$
    
create trigger del_playlist before delete on playlists for each row
	begin
		update manage_playlists set size = manage_playlist_size() - 1;
	end $$
    
create trigger del_song before delete on songs for each row
	begin
		update manage_songs set size = manage_song_size() - 1;
	end $$

delimiter ;