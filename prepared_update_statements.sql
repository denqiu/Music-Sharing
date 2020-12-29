use narayanFall2020group1;

drop procedure if exists set_update;

drop procedure if exists update_strint;

delimiter $$

create procedure set_update(in table_name varchar(255), in arg_type varchar(255), in set_name varchar(255), in set_string varchar(255), in set_int int, in where_name varchar(255), in where_string varchar(255), in where_int int)
	begin
		set @up = concat('update ', table_name, ' set ', set_name, '=? where ', where_name, '=?');
        set @set_string = concat("'", set_string, "'");
        set @set_int = set_int;
        set @where_string = concat("'", where_string, "'");
        set @where_int = where_int;
        prepare stmt from @up;
        if arg_type = 'strint' then
			execute stmt using @set_string, @where_int;
		end if;
        deallocate prepare stmt;
    end $$
    
create procedure update_strint(in table_name varchar(255), in set_name varchar(255), in set_value varchar(255), in where_name varchar(255), in where_value int)
	begin
		call set_update(table_name, 'strint', set_name, set_value, 0, where_name, '', where_value);
	end $$

delimiter ;