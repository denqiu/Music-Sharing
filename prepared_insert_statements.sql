use narayanFall2020group1;

drop function if exists count_columns;

drop function if exists create_insert_questions;

drop procedure if exists set_insert;

drop procedure if exists insert_strings;

drop procedure if exists insert_string;

drop procedure if exists insert_ints;

drop procedure if exists insert_int;

drop procedure if exists insert_intstr;

delimiter $$

create function count_columns(t_name varchar(255)) returns int
	begin
		declare cols int;
		select count(*) into cols from information_schema.columns 
        where table_schema = 'narayanFall2020group1' and table_name = t_name;
        return cols;
    end $$
    
create function create_insert_questions(count_columns int) returns varchar(255)
    begin
		declare i int default 0;
        declare cols varchar(255) default '';
		c: while true do
			set cols = concat(cols, '?');
			set i = i + 1;
            if i = count_columns then
				leave c;
            else
				set cols = concat(cols, ',');
            end if;
        end while c;
        return cols;
    end $$
    
create procedure set_insert(in table_name varchar(255), in arg_type varchar(255), in arg1_string varchar(255), in arg2_string varchar(255), in arg1_int int, in arg2_int int)
	begin
		set @count_cols = count_columns(table_name);
        set @cols = create_insert_questions(@count_cols);
		set @ins = concat('insert into ', table_name, ' values (', @cols, ')');
        set @id = 0;
        set @arg1_string = arg1_string;
        set @arg2_string = arg2_string;
        set @arg1_int = arg1_int;
        set @arg2_int = arg2_int;
        prepare stmt from @ins;
        if arg_type = 'strings' then
			execute stmt using @id, @arg1_string, @arg2_string;
		elseif arg_type = 'string' then
			if table_name = 'song_descriptions' then
				set @id = manage_song_id();
			elseif table_name like 'search%' then
				set @id = get_user_id_logged_in();
			end if;
			execute stmt using @id, @arg1_string;
		elseif arg_type = 'ints' then
			if table_name = 'song_details' then
				set @id = manage_song_id();
				execute stmt using @id, @arg1_int, @arg2_int;
			else
				execute stmt using @arg1_int, @arg2_int;
			end if;
        elseif arg_type = 'int' then
			if table_name = 'song_downloads' or table_name = 'song_listens' then
				set @id = manage_song_id();
			end if;
			execute stmt using @id, @arg1_int;
		elseif arg_type = 'intstr' then
			execute stmt using @id, @arg1_int, @arg1_string;
		end if;
        deallocate prepare stmt;
    end $$
    
create procedure insert_strings(in table_name varchar(255), in arg1 varchar(255), in arg2 varchar(255))
	begin
		call set_insert(table_name, 'strings', arg1, arg2, 0, 0);
	end $$
    
create procedure insert_string(in table_name varchar(255), in arg varchar(255))
	begin
		call set_insert(table_name, 'string', arg, '', 0, 0);
	end $$
    
create procedure insert_ints(in table_name varchar(255), in arg1 int, in arg2 int)
	begin
		call set_insert(table_name, 'ints', '', '', arg1, arg2);
	end $$
    
create procedure insert_int(in table_name varchar(255), in arg int)
	begin
		call set_insert(table_name, 'int', '', '', arg, 0);
	end $$
    
create procedure insert_intstr(in table_name varchar(255), in arg1 int, in arg2 varchar(255))
	begin
		call set_insert(table_name, 'intstr', arg2, '', arg1, 0);
	end $$

delimiter ;