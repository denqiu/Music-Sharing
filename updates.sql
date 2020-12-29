use narayanFall2020group1;

drop procedure if exists update_user_name;

drop procedure if exists reset_password;

drop procedure if exists update_artist;

drop procedure if exists update_genre;

drop procedure if exists edit_message;

drop procedure if exists update_playlist;

drop procedure if exists update_song_name;

drop procedure if exists update_song_to_playlist;

drop procedure if exists increment_song_downloads;

drop procedure if exists increment_song_listens;

delimiter $$
    
create procedure update_user_name(in old_user varchar(255), in new_user varchar(255))
	begin
		set @user_id = get_user_id(old_user);
		call update_strint('accounts', 'user_name', new_user, 'account_id', @user_id);
    end $$
    
create procedure reset_password(in old_user varchar(255), in new_pass varchar(255))
	begin
		set @user_id = get_user_id(old_user);
		call update_strint('accounts', 'password', new_pass, 'account_id', @user_id);
    end $$
    
create procedure update_artist(in old_artist varchar(255), in new_artist varchar(255))
	begin
		call update_strint('artists', 'artist_name', new_artist, 'artist_id', get_artist_id(old_artist));
    end $$
    
create procedure update_genre(in old_genre varchar(255), in new_genre varchar(255))
	begin
		call update_strint('genres', 'genre', new_genre, 'genre_id', get_genre_id(old_genre));
    end $$
    
create procedure edit_message(in msg_date datetime, in new_msg varchar(255))
	begin
		call update_strint('messages', 'message', new_msg, 'message_id', get_message_id(msg_date));
    end $$
    
create procedure update_playlist(in old_playlist varchar(255), in user_name varchar(255), in new_playlist varchar(255))
	begin
		call update_strint('playlists', 'playlist_name', new_playlist, 'playlist_id', get_playlist_id(get_user_id(user_name), old_playlist));
    end $$

create procedure update_song_name(in user_name varchar(255), in old_song varchar(255), in artist_name varchar(255), in genre varchar(255))
	begin
		set @user_id = get_user_id(user_name);
        if @user_id > 0 then
			call update_intstr('songs', @user_id, song_name);
            set @artist_id = get_artist_id(artist_name);
            if @artist_id < 1 then
				call update_artist(artist_name);
				set @artist_id = get_artist_id(artist_name);
            end if;
			set @genre_id = get_genre_id(genre);
            if @genre_id < 1 then
				call update_genre(genre);
				set @genre_id = get_genre_id(genre);
            end if;
            call update_ints('song_details', @artist_id, @genre_id);
		else
			call set_error(concat("'", user_name, "' does not exist in the database."));
		end if;
    end $$
    
create procedure update_song_to_playlist(in user_name varchar(255), in playlist_name varchar(255), in song_user_name varchar(255), in song_name varchar(255))
	begin
		set @user_id = get_user_id(user_name);
		set @song_user_id = get_user_id(song_user_name);
        if @user_id < 1 then
			call set_error(concat("'", user_name, "' does not exist in the database."));
		elseif @song_user_id < 1 then
			call set_error(concat("'", song_user_name, "' does not exist in the database."));
		else
			set @playlist_id = get_playlist_id(@user_id, playlist_name);
			set @song_id = get_song_id(@song_user_id, song_name);
			if @playlist_id < 1 then
				call set_error(concat('Playlist ', playlist_name, ' by user ', user_name, ' does not exist.'));
			elseif @song_id < 1 then
				call set_error(concat('Song ', song_name, ' by user ', user_name, ' does not exist.'));
			else
				call update_ints('contained', @playlist_id, @song_id);
			end if;
		end if;
    end $$

delimiter ;