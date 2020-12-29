from sshtunnel import SSHTunnelForwarder as ssh
import mysql.connector as con
import os
import re

class PySql:
    def __init__(self, host, user, password, database, port = 3306, doPrint = False):
        for _ in range(2):
            e = database == ""
            try:
                self.db = con.connect(host = host, port = port, user = user, password = password, database = database)
                self.db_name = database
                self.cursor = self.db.cursor()
                self.doPrint = doPrint
                self.results = None
                self.__vals = None
            except:
                try:
                    self.db = con.connect(host = host, port = port, user = user, password = password)
                    self.db_name = database
                    self.cursor = self.db.cursor()
                    self.cursor.execute("set sql_notes = 0")
                    self.cursor.execute("create database if not exists {}".format(database))
                    self.cursor.execute("use database {}".format(database))
                    self.doPrint = doPrint
                    self.results = None
                    self.__vals = None
                except:
                    e = True
        if e: 
            print("Please enter a valid host, user, password, or database.")
            quit()
            
    def printResults(self, index = None, printText = True, doPrint = True):
        '''Print out data results.
           printText - Allows data results to be printed.
           index - Prints out a number.
           Note: It may be better to set printText = False if the result being printed is large.'''
        if doPrint:
            print(("" if index is None else "{}. ".format(index)) + (self.results[0] if printText else ""))
            if not self.results[2] is None:
                [print(r) for r in self.results[2]]
            print()
        return self
            
    def writeResults(self, index = None, out = ""):
        '''Write out data results to a file.'''
        if out != "":
            w = open(out, "a+")
            w.write(("" if index is None else "{}. ".format(index)) + self.results[0] + "\n")
            if not self.results[2] is None:
                [w.write(str(r) + "\n") for r in self.results[2]]
            w.write("\n")
            w.close()
        return self
            
    def use(self, database, doPrint = None):
        '''Method for "use database" statement.'''
        if doPrint is None: doPrint = self.doPrint
        u = "use {}".format(database)
        self.cursor.execute(u)
        if doPrint: print(u)
        return self
    
    def columns(self):
        '''Returns columns of a table.'''
        return tuple([f[0] for f in self.cursor.description])
        
    def setArgs(self, *vals):
        self.__vals = vals
        return self
        
    def primaries(self, table):
        '''Returns primary keys of the table.'''
        return tuple([d["Column_name"] for d in self.setArgs("PRIMARY").query("show keys from {} where Key_name = %s".format(table)).results[2]])
    
    def __checkError(self, err):
        if "Duplicate" in err:
            r = re.search("entry '.*'.* key '.*\.(.*)'", err)
            err = "An account already exists with this {}".format(r.group(1).replace("_", " "))
        return err
    
    def modify(self, query, *vals):
        '''For inserts, updates, or deletes. Statements that modify the database.'''
        try:
            if len(vals) < 1:
                query = query.replace("!!NEWLINE!!", "\n")
                q = query.split("!!VALS!!")
                vals = [int(v[:-len("!!INT!!")]) if "!!INT!!" in v else v[1:-1] for v in q[1:]]
                self.cursor.execute(q[0], vals)
                query = query.replace("!!VALS!!", "").replace("!!INT!!", "")
            else:
                self.cursor.execute(query, vals)
            self.db.commit()
            for v in vals: query = query.replace("%s", str(v), 1)
            return query
        except con.Error as e:
            return self.__checkError(e.msg)
        
    def query(self, q, index = None, printText = True, doPrint = None, out = ""):
        '''Statements that don't modify the database and just pull out data, 
           such as select statements.'''
        try:
            if doPrint is None: doPrint = self.doPrint
            if self.__vals is None:
                if q.strip() != "": self.cursor.execute(q)
            else:
                if q.strip() != "":
                    self.cursor.execute(q, self.__vals)
                    for v in self.__vals:
                        q = q.replace('%s', "'{}'".format(v) if isinstance(v, str) else v.__str__(), 1)
                self.__vals = None
            if q.strip() == "":
                self.results = ("Query cannot be empty. Please enter a query.", None, None)
            else:
                cols = self.columns()
                self.results = (q, cols, [dict(zip(cols, row)) for row in self.cursor.fetchall()])
        except con.Error as e:
            self.results = (self.__checkError(e.msg), None, None)
        return self.printResults(index, printText, doPrint).writeResults(index, out)
    
    def source(self, readFile, outFile = "", printText = True, doPrint = None):
        '''Executes queries and statements in .txt or .sql files.'''
        if doPrint is None: doPrint = self.doPrint
        if outFile != "" and os.path.exists(outFile): os.remove(outFile)
        print("Source " + readFile + "\n")
        r, q, s = ([], open(readFile, encoding = "utf-8"), "")
        for i in q: 
            if ".sql" in readFile:
                b = "#" in i or "--" in i or "delimiter" in i
                if b: continue
                else:
                    if i.strip() == "":
                        if s == "": continue
                    else:
                        i = str(i).replace("$$", "")
                        s += i
                        continue
            elif ".txt" in readFile: 
                if i.strip() == "": continue
                else: s = i
            if "set" in s or s[:len("use")] == "use":
                self.cursor.execute(s)
            else:
                j = len(r)+1
                if s[:len("insert")] == "insert" or s[:len("update")] == "update" or s[:len("delete")] == "delete":
                    m = self.modify(s)
                    self.results = (m, None, None)
                    self.printResults(j, printText, doPrint).writeResults(j, outFile)
                    r.append(m)
                elif s[:len("create")] == "create" or s[:len("drop")] == "drop":
                    self.cursor.execute(s)
                    self.results = (s, None, None)
                    self.printResults(j, printText, doPrint).writeResults(j, outFile)
                    r.append(s)
                else: 
                    r.append(self.query(s, index=j, printText=printText, doPrint=doPrint, out=outFile).results)
            s = ""
        q.close()
        self.results = (readFile, "", r)
        return self
    
    def backupTable(self, table):
        '''Backs up table.'''
        bd = self.query("show columns from {}".format(table)).results[2]
        c = ", ".join("{} {} {}{}".format(d["Field"], str(d["Type"])[2:-1], "null" if d["Null"] == "YES" else "not null", "" if d["Extra"] == "" else " " + d["Extra"]) for d in bd)
        p = self.primaries(table)
        if len(p) > 0: c += ", primary key ({})".format(", ".join(i for i in p))
        s = self.query("select * from {}".format(table)).results[2]
        for i in s: 
            if i == "date": i["date"] = i["date"].__str__()
        b = open("backup-{}.txt".format(table), "w+", encoding = "utf-8")
        b.write("drop table if exists {}\n".format(table))
        b.write("create table {} ({}) engine = INNODB\n".format(table, c))
        for i, v in enumerate(s): 
            b.write("insert into {} values ({})!!VALS!!{}{}".format(table, ", ".join(["%s"]*len(v)), "!!VALS!!".join(str(k) + "!!INT!!" if "int" in str(bd[j]["Type"]) else "'{}'".format(k.replace("\n", "!!NEWLINE!!")) for j, k in enumerate(v.values())), "\n" if i < len(s)-1 else ""))
        b.close()
        return self
    
    def createTable(self, table, outFile = "", printText = True, doPrint = None, setForeignKeyChecks = False):  
        if doPrint is None: doPrint = self.doPrint
        if setForeignKeyChecks: self.setForeignKeyChecks(0)
        self.source("backup-{}.txt".format(table), outFile, printText, doPrint) 
        if setForeignKeyChecks: self.setForeignKeyChecks(1)
        return self
    
    def setForeignKeyChecks(self, c):
        self.cursor.execute("set foreign_key_checks = {}".format(c))
        return self
        
    def truncate(self, table, doPrint = None):
        '''Truncates, or clears all data from the table.'''
        if doPrint is None: doPrint = self.doPrint
        self.backupTable(table)
        t = "truncate {}".format(table)
        self.cursor.execute(t)
        if doPrint: print(t)
        return self
    
    def showTables(self):
        self.query("show full tables where table_type <> 'VIEW'")
        return self
    
    def showViews(self):
        self.query("show full tables where table_type = 'VIEW'")
        return self
    
    def showFunctions(self):
        self.query("show function status where db = '{}'".format(self.db_name))
        return self
        
    def showProcedures(self):
        self.query("show procedure status where db = '{}'".format(self.db_name))
        return self
    
    def showProcedureParameters(self, procedure):
        self.setArgs(procedure).query("select * from information_schema.parameters where specific_name = %s")
        return self
    
    def callProcedure(self, query, procName, *args):
        try:
            self.cursor.callproc(procName, args)
            self.setArgs(*args).query(query)
        except con.Error as e:
            self.results = (self.__checkError(e.msg), None, None)
        return self
    
    def callFunction(self, query, *args):
        try:
            self.__function = True
            self.setArgs(*args).query(query)
        except con.Error as e:
            self.results = (self.__checkError(e.msg), None, None)
        return self
    
    def update_user_name(self, new_user, old_user):
        user_id = self.callFunction("select get_user_id(%s) as id", old_user).results[2][0]['id']
        if user_id > 0:
            q = "update accounts set user_name = %s where account_id = %s"
            u = self.modify(q, new_user, user_id)
            if "update" in q and "update" in u:
                q = "select * from accounts where user_name = %s"
                self.setArgs(new_user).query(q)
            else:
                self.results = (u, None, None)
        else:
            self.results = ("No account exists with user name {}".format(old_user), None, None)
        return self
    
    def reset_password(self, old_user, new_pass):
        user_id = self.callFunction("select get_user_id(%s) as id", old_user).results[2][0]['id']
        q = "update accounts set password = %s where account_id = %s"
        r = self.modify(q, new_pass, user_id)
        if "update" in q and "update" in r:
            q = "select * from accounts where account_id = %s"
            self.setArgs(user_id).query(q)
        else:
            self.results = (r, None, None)
        return self
    
    def set_user_logged_in(self, user_name = ""):
        user_id = self.callFunction("select get_user_id(%s) as id", user_name).results[2][0]['id']
        q = "update logged_in set user_id = %s"
        u = self.modify(q, user_id)
        if "update" in q and "update" in u:
            self.callProcedure("select user_id from logged_in", 'set_search')
            self.query("select if(get_user_id_logged_in() > 0, 'YES', 'NO') as is_logged_in")
        else:
            self.results = (u, None, None)
        return self
          
    def set_current_user(self, user_name = ""):
        user_id = self.callFunction("select get_user_id(%s) as id", user_name).results[2][0]['id']
        q = "update cur_user set user_id = %s"
        u = self.modify(q, user_id)
        if "update" in q and "update" in u:
            self.setArgs(user_id).query("select user_name from accounts where account_id = %s")
        else:
            self.results = (u, None, None)
        return self
            
    def update_artist_name(self, old_artist, new_artist):
        artist_id = self.callFunction("select get_artist_id(%s) as id", old_artist).results[2][0]['id']
        if artist_id > 0:
            q = "update artists set artist_name = %s where artist_id = %s"
            u = self.modify(q, new_artist, artist_id)
            if "update" in q and "update" in u:
                q = "select * from artists where artist_name = %s"
                self.setArgs(new_artist).query(q)
            else:
                self.results = (u, None, None)
        else:
            self.results = ("No artist exists with artist name {}".format(old_artist), None, None)
        return self
               
    def update_genre(self, old_genre, new_genre):
        genre_id = self.callFunction("select get_genre_id(%s) as id", old_genre).results[2][0]['id']
        if genre_id > 0:
            q = "update genres set genre = %s where genre_id = %s"
            u = self.modify(q, new_genre, genre_id)
            if "update" in q and "update" in u:
                q = "select * from genres where genre = %s"
                self.setArgs(new_genre).query(q)
            else:
                self.results = (u, None, None)
        else:
            self.results = ("No genre exists with genre {}".format(old_genre), None, None)
        return self
               
    def edit_message(self, msg_date, new_msg):
        msg_id = self.callFunction("select get_message_id(%s) as id", msg_date).results[2][0]['id']
        if msg_id > 0:
            q = "update messages set message = %s where message_id = %s"
            u = self.modify(q, new_msg, msg_id)
            if "update" in q and "update" in u:
                q = "select * from messages where message_id = %s"
                self.setArgs(msg_id).query(q)
            else:
                self.results = (u, None, None)
        else:
            self.results = ("No message exists with time stamp {}".format(msg_date), None, None)
        return self
            
    def update_playlist(self, playlist_id, new_playlist):
        if playlist_id > 0:
            q = "update playlists set playlist_name = %s where playlist_id = %s"
            u = self.modify(q, new_playlist, playlist_id)
            if "update" in q and "update" in u:
                q = "select * from playlists where playlist_id = %s"
                self.setArgs(playlist_id).query(q)
            else:
                self.results = (u, None, None)
        else:
            self.results = ("This playlist doesn't exist.", None, None)
        return self
    
    def update_song_name(self, song_id, new_song):
        if song_id > 0:
            if new_song.strip() == "":
                self.results = ("Song name cannot be empty. Please create a new song name.", None, None)
            else:
                q = "update songs set song_name = %s where song_id = %s"
                u = self.modify(q, new_song, song_id)
                if "update" in q and "update" in u:
                    q = "select * from songs where song_id = %s"
                    self.setArgs(song_id).query(q)
                else:
                    self.results = (u, None, None)
        else:
            self.results = ("This song doesn't exist.", None, None)
        return self
        
    def update_song_artist(self, song_id, new_artist):
        if song_id > 0:
            if new_artist.strip() == "": new_artist = "N/A"
            artist_id = self.callFunction("select get_artist_id(%s) as id", new_artist).results[2][0]['id']
            if artist_id < 1:
                self.callProcedure("select * from artists where artist_name = %s", 'add_artist', new_artist)
                artist_id = self.callFunction("select get_artist_id(%s) as id", new_artist).results[2][0]['id']
            q = "update song_details set artist_id = %s where song_id = %s"
            u = self.modify(q, artist_id, song_id)
            if "update" in q and "update" in u:
                q = "select * from song_details where song_id = %s"
                self.setArgs(song_id).query(q)
            else:
                self.results = (u, None, None)
        else:
            self.results = ("This song doesn't exist", None, None)
        return self
        
    def update_song_genre(self, song_id, new_genre):
        if song_id > 0:
            if new_genre.strip() == "": new_genre = "N/A"
            genre_id = self.callFunction("select get_genre_id(%s) as id", new_genre).results[2][0]['id']
            if genre_id < 1:
                self.callProcedure("select * from genres where genre = %s", 'add_genre', new_genre)
                genre_id = self.callFunction("select get_genre_id(%s) as id", new_genre).results[2][0]['id']
            q = "update song_details set genre_id = %s where song_id = %s"
            u = self.modify(q, genre_id, song_id)
            if "update" in q and "update" in u:
                q = "select * from song_details where song_id = %s"
                self.setArgs(song_id).query(q)
            else:
                self.results = (u, None, None)
        else:
            self.results = ("This song doesn't exist.", None, None)
        return self
    
    def update_song_description(self, song_id, descr):
        if song_id > 0:
            q = "update song_descriptions set description = %s where song_id = %s"
            u = self.modify(q, descr, song_id)
            if "update" in q and "update" in u:
                q = "select * from song_descriptions where song_id = %s"
                self.setArgs(song_id).query(q)
            else:
                self.results = (u, None, None)
        else:
            self.results = ("This song doesn't exist", None, None)
        return self
    
    def increment_song_downloads(self, song_id):
        if song_id > 0:
            down = self.callFunction("select get_song_downloads(%s) as down", song_id).results[2][0]['down']
            q = "update song_downloads set downloads = %s where song_id = %s"
            u = self.modify(q, (down+1), song_id)
            if "update" in q and "update" in u:
                q = "select * from song_downloads where song_id = %s"
                self.setArgs(song_id).query(q)
            else:
                self.results = (u, None, None)
        else:
            self.results = ("This song doesn't exist.", None, None)
        return self   
    
    def increment_song_listens(self, song_id):
        if song_id > 0:
            lis = self.callFunction("select get_song_listens(%s) as lis", song_id).results[2][0]['lis']
            q = "update song_listens set listens = %s where song_id = %s"
            u = self.modify(q, (lis+1), song_id)
            if "update" in q and "update" in u:
                q = "select * from song_listens where song_id = %s"
                self.setArgs(song_id).query(q)
            else:
                self.results = (u, None, None)
        else:
            self.results = ("This song doesn't exist.", None, None)
        return self   
    
    def set_order(self, order):
        if order == "desc":
            order = "asc"
        else:
            order = "desc"
        return order
       
    def set_search_home(self, song, user, artist, genre, playlist):
        user_id = self.query("select get_user_id_logged_in() as user_id").results[2][0]['user_id']
        q = "update search_home_songs set song = %s, user = %s, artist = %s, genre = %s, playlist = %s where user_id = %s"
        s = self.modify(q, song, user, artist, genre, playlist, user_id)
        if "update" in q and "update" in s:
            q = "update order_home_songs set song = %s, user = %s, artist = %s, genre = %s, playlist = %s, download = %s, play = %s where user_id = %s"
            self.modify("", "", "", "", "", "", "", user_id)
            q = "select * from search_home_songs where user_id = %s"
            self.setArgs(user_id).query(q)
        else:
            self.results = (s, None, None)
        return self
    
    def set_order_home(self, order):
        user_id = self.query("select get_user_id_logged_in() as user_id").results[2][0]['user_id']
        q = "select {} from order_home_songs where user_id = %s".format(order)
        new_order = self.set_order(self.setArgs(user_id).query(q).results[2][0][order])
        q = "update order_home_songs set {} = %s where user_id = %s".format(order)
        s = self.modify(q, new_order, user_id)
        if "update" in q and "update" in s:
            q = "select {} from order_home_songs where user_id = %s".format(order)
            self.setArgs(user_id).query(q)
        else:
            self.results = (s, None, None)
        return self
    
    def set_search_user(self, song, artist, genre):
        user_id = self.query("select get_user_id_logged_in() as user_id").results[2][0]['user_id']
        q = "update search_user_songs set song = %s, artist = %s, genre = %s where user_id = %s"
        s = self.modify(q, song, artist, genre, user_id)
        if "update" in q and "update" in s:
            q = "update order_user_songs set song = %s, artist = %s, genre = %s, download = %s, play = %s where user_id = %s"
            self.modify("", "", "", "", "", user_id)
            q = "select * from search_user_songs where user_id = %s"
            self.setArgs(user_id).query(q)
        else:
            self.results = (s, None, None)
        return self
    
    def set_order_user(self, order):
        user_id = self.query("select get_user_id_logged_in() as user_id").results[2][0]['user_id']
        q = "select {} from order_user_songs where user_id = %s".format(order)
        new_order = self.set_order(self.setArgs(user_id).query(q).results[2][0][order])
        q = "update order_user_songs set {} = %s where user_id = %s".format(order)
        s = self.modify(q, new_order, user_id)
        if "update" in q and "update" in s:
            q = "select {} from order_user_songs where user_id = %s".format(order)
            self.setArgs(user_id).query(q)
        else:
            self.results = (s, None, None)
        return self
    
    def set_search_accounts(self, user, admin):
        user_id = self.query("select get_user_id_logged_in() as user_id").results[2][0]['user_id']
        q = "update search_accounts set user = %s, admin = %s where user_id = %s"
        s = self.modify(q, user, admin, user_id)
        if "update" in q and "update" in s:
            q = "update order_accounts set id = %s, user = %s, password = %s, admin = %s, songs = %s, playlists = %s where user_id = %s"
            self.modify("", "", "", "", "", "", user_id)
            q = "select * from search_accounts where user_id = %s"
            self.setArgs(user_id).query(q)
        else:
            self.results = (s, None, None)
        return self
    
    def set_order_accounts(self, order):
        user_id = self.query("select get_user_id_logged_in() as user_id").results[2][0]['user_id']
        q = "select {} from order_accounts where user_id = %s".format(order)
        new_order = self.set_order(self.setArgs(user_id).query(q).results[2][0][order])
        q = "update order_accounts set {} = %s where user_id = %s".format(order)
        s = self.modify(q, new_order, user_id)
        if "update" in q and "update" in s:
            q = "select {} from order_accounts where user_id = %s".format(order)
            self.setArgs(user_id).query(q)
        else:
            self.results = (s, None, None)
        return self
    
    def delete_user(self, user_name):
        user_id = self.callFunction("select get_user_id(%s) as id", user_name).results[2][0]['id']
        log_user_id = self.query("select get_user_id_logged_in() as id").results[2][0]['id']
        if user_id == log_user_id:
            self.results = ("Cannot delete user. User is already logged in.", None, None)
        else:
#             sizes = {"songs": 0, "playlists": 0, "admins": 0}
#             for t, _ in sizes:  
#                 q = "select * from {} where user_id = %s".format(t)
#                 sizes[t] = len(self.setArgs(user_id).query(q).results[2])
            q = "delete from accounts where account_id = %s"
            d = self.modify(q, user_id)
            if "delete" in q and "delete" in d:
                q = "update manage_songs"
                self.query("select * from accounts")
            else:
                self.results = (d, None, None)
        return self
    
    def remove_admin(self, user_name):
        admin_id = self.callFunction("select get_admin_id(get_user_id(%s)) as id", user_name).results[2][0]['id']
        if admin_id > 0:
            q = "delete from admins where admin_id = %s"
            d = self.modify(q, admin_id)
            if "delete" in q and "delete" in d:
                self.query("select * from admins")
            else:
                self.results = (d, None, None)
        else:
            self.results = ("No admin exists with user name {}".format(user_name))
        return self
    
    def remove_message(self, msg_date):
        msg_id = self.callFunction("select get_message_id(%s) as id", msg_date).results[2][0]['id']
        if msg_id > 0:
            q = "delete from messages where message_id = %s"
            d = self.modify(q, msg_id)
            if "delete" in q and "delete" in d:
                self.query("select * from messages")
            else:
                self.results = (d, None, None)
        else:
            self.results = ("No message exists with time stamp {}".format(msg_date), None, None)
        return self
    
    def delete_playlist(self, playlist_id):
        if playlist_id > 0:
            q = "delete from playlists where playlist_id = %s"
            d = self.modify(q, playlist_id)
            if "delete" in q and "delete" in d:
                self.query("select * from playlists")
            else:
                self.results = (d, None, None)
        else:
            self.results = ("This playlist doesn't exist.", None, None)
        return self
    
    def delete_song(self, song_id):
        if song_id > 0:
            q = "delete from songs where song_id = %s"
            d = self.modify(q, song_id)
            if "delete" in q and "delete" in d:
                self.query("select * from songs")
            else:
                self.results = (d, None, None)
        else:
            self.results = ("This song doesn't exist.", None, None)
        return self
    
    def remove_song_from_playlist(self, playlist_id, song_id):
        q = "delete from contained where playlist_id = %s and song_id = %s"
        d = self.modify(q, playlist_id, song_id)
        if "delete" in q and "delete" in d:
            self.setArgs(playlist_id).query("select * from contained where playlist_id = %s")
        else:
            self.results = (d, None, None)
        return self
    
    def close(self):
        self.db.close()
        
class PySqlAccess(PySql):
    def __init__(self, doPrint = False):
        f = open(os.getcwd() + "\\pySqlAccess.txt", encoding = "utf-8")
        host, user, password, database = ("", "", "", "")
        for i in f:
            s = i.split(":")
            s[1] = str(s[1]).strip()
            if s[0] == "host": host = s[1]
            elif s[0] == "user": user = s[1]
            elif s[0] == "password": password = s[1]
            elif s[0] == "database": database = s[1]
        PySql.__init__(self, host=host, user=user, password=password, database=database, doPrint=doPrint)
        
class SatoshiSql(PySql):
    def __init__(self, user, ssh_password, db_password, database, doPrint = False):
        self.tunnel = ssh(('satoshi.cis.uncw.edu'), ssh_username = user, ssh_password = ssh_password, remote_bind_address = ('127.0.0.1', 3306)) 
        self.tunnel.start()
        PySql.__init__(self, '127.0.0.1', user, db_password, database, self.tunnel.local_bind_port, doPrint)
    
    def close(self):
        PySql.close(self)
        self.tunnel.close()
    
class SatoshiSqlAccess(SatoshiSql):
    def __init__(self, doPrint = False):
        f = open(os.getcwd() + "\\satoshiSqlAccess.txt", encoding = "utf-8")
        user, ssh_password, db_password, database = ("", "", "", "")
        for i in f:
            s = i.split(":")
            s[1] = str(s[1]).strip()
            if s[0] == "user": user = s[1]
            elif s[0] == "ssh_password": ssh_password = s[1]
            elif s[0] == "db_password": db_password = s[1]
            elif s[0] == "database": database = s[1]
        SatoshiSql.__init__(self, user=user, ssh_password=ssh_password, db_password=db_password, database=database, doPrint=doPrint)