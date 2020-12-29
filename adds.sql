use narayanFall2020group1;

drop procedure if exists add_account;

drop procedure if exists set_admin;

drop procedure if exists add_artist;

drop procedure if exists add_genre;

drop procedure if exists new_message;

drop procedure if exists add_playlist;

drop procedure if exists add_song;

drop procedure if exists add_song_to_playlist;

drop procedure if exists set_search;

delimiter $$
    
create procedure add_account(in user_name varchar(255), in password varchar(255))
	begin
		call insert_strings('accounts', user_name, password);
    end $$
    
create procedure set_admin(in user_name varchar(255))
	begin
		set @user_id = get_user_id(user_name);
		if get_admin_id(@user_id) < 1 then
			call insert_int('admins', @user_id);
		else
			call set_error(concat('No admin exists with user name ', user_name));
		end if;
    end $$
    
create procedure add_artist(in artist_name varchar(255))
	begin
		call insert_string('artists', artist_name);
    end $$
    
create procedure add_genre(in genre varchar(255))
	begin
		call insert_string('genres', genre);
    end $$
    
create procedure new_message(in message varchar(255), in sender varchar(255), receiver varchar(255))
	begin
		set @sender_id = get_user_id(sender);
        set @receiver_id = get_user_id(receiver);
        if @sender_id < 1 then
			call set_error(concat('No account exists with user name ', sender));
		elseif @receiver_id < 1 then
			call set_error(concat('No account exists with user name ', receiver));
        else
			call insert_strings('messages', message, '2020-10-31 00:00:00');
			call insert_int('sent', @sender_id);
            call insert_int('received', @receiver_id);
        end if;
    end $$
    
create procedure add_playlist(in playlist_name varchar(255), in user_name varchar(255))
	begin
		set @user_id = get_user_id(user_name);
        if @user_id > 0 then
			call insert_intstr('playlists', @user_id, playlist_name);
		else
			call set_error(concat('No account exists with user name ', user_name));
		end if;
    end $$

create procedure add_song(in user_name varchar(255), in song_name varchar(255), in artist_name varchar(255), in genre varchar(255), in descr varchar(255))
	begin
		set @user_id = get_user_id(user_name);
        if @user_id > 0 then
			call insert_intstr('songs', @user_id, song_name);
            set @artist = artist_name;
            set @genre = genre;
            if is_empty(@artist) then
				set @artist = 'N/A';
			end if;
            set @artist_id = get_artist_id(@artist);
            if @artist_id < 1 then
				call add_artist(@artist);
				set @artist_id = get_artist_id(@artist);
            end if;
            if is_empty(@genre) then
				set @genre = 'N/A';
			end if;
			set @genre_id = get_genre_id(@genre);
            if @genre_id < 1 then
				call add_genre(@genre);
				set @genre_id = get_genre_id(@genre);
            end if;
            call insert_ints('song_details', @artist_id, @genre_id);
            call insert_string('song_descriptions', descr);
            call insert_int('song_downloads', 0);
            call insert_int('song_listens', 0);
		else
			call set_error(concat('No account exists with user name ', user_name));
		end if;
    end $$
    
create procedure add_song_to_playlist(in playlist_id int, in song_id int)
	begin
		call insert_ints('contained', playlist_id, song_id);
    end $$
    
create procedure set_search()
	begin
		if get_search_home_id() < 1 then
			insert into search_home_songs values ();
		end if;
		if get_search_user_id() < 1 then
			insert into search_user_songs values ();
		end if;
		if get_search_accounts_id() < 1 then
			insert into search_accounts values ();
		end if;
        if get_order_home_id() < 1 then
			insert into order_home_songs values ();
		end if;
		if get_order_user_id() < 1 then
			insert into order_user_songs values ();
		end if;
		if get_order_accounts_id() < 1 then
			insert into order_accounts values ();
		end if;
    end $$

delimiter ;