from flask import Flask, request, render_template, redirect, url_for
from pySql import SatoshiSqlAccess as sat

app = Flask(__name__)
db = sat(True)

def get_user_url(user_name, is_admin):
    return "{}_admin_{}".format(user_name, is_admin)

def check_logged_in(user_name, is_admin, check_log = True):
    if check_log:
        logged_in = db.query("select get_user_id_logged_in() as user_id").results[2][0]['user_id']
        is_in = logged_in > 0
    else:
        is_in = True
    if is_in:
        user_id = db.callFunction("select get_user_id(%s) as user_id", user_name).results[2][0]['user_id']
        if user_id > 0:
            a = db.callFunction("select if(get_admin_id(get_user_id(%s)) > 0, 'YES', 'NO') as is_admin", user_name).results[2][0]['is_admin']
            is_in = is_admin == a
        else:
            is_in = False
    return is_in

def search_table(name):
    db.cursor.execute("drop table if exists table_{}".format(name))
    db.cursor.execute("create table table_{0} as select * from view_{0}".format(name))
    
@app.route('/close')
def close():
    db.close()
    return "Database connection closed"

@app.route('/', methods=['GET', 'POST'])
def home(): 
    logged_in = db.query("select get_user_id_logged_in() as user_id").results[2][0]['user_id']
    user_url = ""
    is_logged = logged_in > 0
    if is_logged:
        q = "select get_user_name(%s) as user_name"
        user_name = db.callFunction(q, logged_in).results[2][0]['user_name']
        is_admin = db.callFunction("select if(get_admin_id(%s) > 0, 'YES', 'NO') as is_admin", logged_in).results[2][0]['is_admin']
        user_url = get_user_url(user_name, is_admin)
    if request.method == 'POST':
        r = request.form
        if "search" in r:
            song = r["search_song"].strip()
            user = r["search_user"].strip()
            artist = r["search_artist"].strip()
            genre = r["search_genre"].strip()
            playlist = r["search_playlist"].strip()
            args, res, n, k = ([], (song, user, artist, genre, playlist), [], ("Song", "User", "Artist", "Genre", "Playlist"))
            db.set_search_home(song, user, artist, genre, playlist)
            for i, v in enumerate(res):
                if v != "": 
                    n.append(k[i] + " like %s")
                    args.append("%{}%".format(v))
            if len(args) > 0:
                q = " and ".join(n)
                q = "select * from table_home_songs where " + q
                search_table("home_songs")
                columns, rows = db.setArgs(*args).query(q).results[1:]
                return render_template('home.html', columns = columns[2:], rows = rows, is_logged = is_logged, user_url = user_url, res = res)
        elif "order" in list(r.keys())[0]:
            order = list(r.keys())[0]
            order = str(order).lower().replace("order_", "")
            o = db.set_order_home(order).results[2][0][order]
            order = order.capitalize()
            search_table("home_songs")
            columns, rows = db.query("select * from table_home_songs order by {} {}".format(order, o)).results[1:]
            res = db.query("select * from search_home_songs where user_id = get_user_id_logged_in()").results[2]
            res = [list(r.values()) for r in res]
            return render_template('home.html', columns = columns[2:], rows = rows, is_logged = is_logged, user_url = user_url, res = res[1:])
        else:
            song_id = int(list(r.keys())[0])
            action = list(r.values())[0]
            if action == "Download":
                db.increment_song_downloads(song_id)
            elif action == "Play":
                db.increment_song_listens(song_id) 
    search_table("home_songs")
    columns, rows = db.query("select * from view_home_songs").results[1:]
    res = db.query("select * from search_home_songs where user_id = get_user_id_logged_in()").results[2]
    res = [list(r.values()) for r in res]
    return render_template('home.html', columns = columns[2:], rows = rows, is_logged = is_logged, user_url = user_url, res = res[1:])

@app.route('/sign_up', methods=['GET', 'POST'])
def sign_up():
    error_msg, user_name = ('', '')
    if request.method == 'POST':
        userDetails = request.form
        user_name = userDetails['user_name']
        password = userDetails['password']
        q = "select * from accounts where user_name = %s and password = %s"
        results = db.callProcedure(q, "add_account", user_name, password).results
        if results[2] is None:
            error_msg = results[0]
        else:
            return redirect("login")
    return render_template('sign_up.html', error_msg = error_msg, user_name = user_name)

@app.route('/reset', methods=['GET', 'POST'])
def reset():
    error_msg, user_name = ('', '')
    if request.method == 'POST':
        userDetails = request.form
        user_name = userDetails['user_name'].strip()
        if user_name == "":
            error_msg = "User name cannot be empty. Please enter a user name."
        else:
            password = userDetails['password']
            q = "select * from accounts where user_name = %s"
            results = db.setArgs(user_name).query(q).results[2]
            if len(results) > 0:
                results = db.reset_password(user_name, password).results
                if results[2] is None:
                    error_msg = results[0]
                else:
                    return redirect("login")
            else:
                error_msg = "No account exists with user name {}".format(user_name)
    return render_template("reset.html", error_msg = error_msg, user_name = user_name)

@app.route('/login', methods=['GET', 'POST'])
def login():
    error_msg, user_name = ('', '')
    db.set_user_logged_in()
    if request.method == 'POST':
        userDetails = request.form
        user_name = userDetails['user_name']
        password = userDetails['password']
        q = "select * from accounts where user_name = %s and binary password = %s"
        results = db.setArgs(user_name, password).query(q).results[2]
        if len(results) > 0:
            db.set_user_logged_in(user_name)
            is_admin = db.callFunction("select if(get_admin_id(get_user_id(%s)) > 0, 'YES', 'NO') as is_admin", user_name).results[2][0]['is_admin']
            return redirect(url_for("user", user_name = user_name, is_admin = is_admin))
        else:
            q = "select * from accounts where user_name = %s"
            results = db.setArgs(user_name).query(q).results[2]
            if len(results) > 0:
                if password.strip() == "":
                    error_msg = "Password cannot be empty. Please enter a password."
                else:
                    error_msg = "Password doesn't match. Try again."
            else:
                error_msg = "No account exists with user name {}".format(user_name)
    return render_template("login.html", error_msg = error_msg, user_name = user_name)

@app.route('/user/<user_name>_admin_<is_admin>', methods=['GET', 'POST'])
def user(user_name, is_admin):
    if not check_logged_in(user_name, is_admin, False): return redirect(url_for("home"))
    db.set_current_user(user_name)
    logged_in = db.query("select get_user_id_logged_in() as user_id").results[2][0]['user_id']
    logged_admin = db.callFunction("select if(get_admin_id(%s) > 0, 'YES', 'NO') as is_admin", logged_in).results[2][0]['is_admin']
    logged_user = db.query("select get_user_name_logged_in() as user_name").results[2][0]['user_name']
    logged_url = get_user_url(logged_user, logged_admin)
    user_url = get_user_url(user_name, is_admin)
    if request.method == 'POST':
        r = request.form
        if "new_user" in r:
            new_user = r['new_user']
            if new_user != user_name:
                results = db.update_user_name(new_user, user_name).results
                if not results[2] is None:
                    return redirect(url_for("user", user_name = results[2][0]['user_name'], is_admin = is_admin))
        elif "search" in r:
            song = r["search_song"].strip()
            artist = r["search_artist"].strip()
            genre = r["search_genre"].strip()
            args, res, n, k = ([], (song, artist, genre), [], ("Song", "Artist", "Genre"))
            db.set_search_user(song, artist, genre)
            for i, v in enumerate(res):
                if v != "": 
                    n.append(k[i] + " like %s")
                    args.append("%{}%".format(v))
            if len(args) > 0:
                q = " and ".join(n)
                q = "select * from table_user_songs where " + q
                search_table("user_songs")
                columns, rows = db.setArgs(*args).query(q).results[1:]
                return render_template('user.html', columns = columns[2:], rows = rows, user_url = user_url, user_name = user_name, is_admin = is_admin, is_logged = logged_in > 0, logged_url = logged_url, logged_admin = logged_admin, res = res)
        elif "order" in list(r.keys())[0]:
            order = list(r.keys())[0]
            order = str(order).lower().replace("order_", "")
            o = db.set_order_user(order).results[2][0][order]
            order = order.capitalize()
            search_table("user_songs")
            columns, rows = db.query("select * from table_user_songs order by {} {}".format(order, o)).results[1:]
            res = db.query("select * from search_user_songs where user_id = get_user_id_logged_in()").results[2]
            res = [list(r.values()) for r in res]
            return render_template('user.html', columns = columns[2:], rows = rows, user_url = user_url, user_name = user_name, is_admin = is_admin, is_logged = logged_in > 0, logged_url = logged_url, logged_admin = logged_admin, res = res[1:])
        else:
            song_id = int(list(r.keys())[0])
            action = list(r.values())[0]
            if action == "Download":
                db.increment_song_downloads(song_id)
            elif action == "Play":
                db.increment_song_listens(song_id)
            else:
                db.delete_song(song_id)
    search_table("user_songs")
    columns, rows = db.query("select * from view_user_songs").results[1:]
    res = db.query("select * from search_user_songs where user_id = get_user_id_logged_in()").results[2]
    res = [list(r.values()) for r in res]
    return render_template('user.html', columns = columns[2:], rows = rows, user_url = user_url, user_name = user_name, is_admin = is_admin, is_logged = logged_in > 0, logged_url = logged_url, logged_admin = logged_admin, res = res[1:])

@app.route('/upload/<user_name>_admin_<is_admin>', methods=['GET', 'POST'])
def upload(user_name, is_admin):
    if not check_logged_in(user_name, is_admin): return redirect(url_for("home"))
    error_msg, song, artist, genre, descr = ('', '', '', '', '')
    if request.method == 'POST':
        r = request.form
        song = r['song']
        artist = r['artist']
        genre = r['genre']
        descr = r['description']
        search_table("songs")
        q = "select * from table_songs where User = %s and Song = %s and Artist = %s and Genre = %s and Description = %s"
        results = db.callProcedure(q, "add_song", user_name, song, artist, genre, descr).results
        if results[2] is None: error_msg = results[0]
    return render_template('upload.html', error_msg = error_msg, user_url = get_user_url(user_name, is_admin), song = song, artist = artist, genre = genre, descr = descr)
    
@app.route('/song/<song_name>_user_<user_name>_id_<song_id>', methods=['GET', 'POST'])
def song(song_name, user_name, song_id):
    results = db.setArgs(song_id).query("select * from songs where song_id = %s").results[2]
    if len(results) < 1: return redirect(url_for("home"))
    error_msg = ''
    artist = db.callFunction("select get_song_artist_name(%s) as artist", song_id).results[2][0]['artist']
    genre = db.callFunction("select get_song_genre(%s) as genre", song_id).results[2][0]['genre']
    descr = db.callFunction("select get_song_description(%s) as descr", song_id).results[2][0]['descr']
    
    logged_in = db.query("select get_user_id_logged_in() as user_id").results[2][0]['user_id']
    logged_admin = db.callFunction("select if(get_admin_id(%s) > 0, 'YES', 'NO') as is_admin", logged_in).results[2][0]['is_admin']
    logged_user = db.query("select get_user_name_logged_in() as user_name").results[2][0]['user_name']
    logged_url = get_user_url(logged_user, logged_admin)
    is_admin = db.callFunction("select if(get_admin_id(get_user_id(%s)) > 0, 'YES', 'NO') as is_admin", user_name).results[2][0]['is_admin']
    user_url = get_user_url(user_name, is_admin)
    if request.method == 'POST':
        r = request.form
        song = r['song']
        artist = r['artist']
        genre = r['genre']
        descr = r['description']
        search_table("songs")
        song_id = int(song_id)
        db.update_song_artist(song_id, artist)
        db.update_song_genre(song_id, genre)
        db.update_song_description(song_id, descr)
        results = db.update_song_name(song_id, song).results
        if results[2] is None: 
            error_msg = results[0]
        else:
            return redirect(url_for("song", song_name = song, user_name = user_name, song_id = song_id))
    return render_template('song.html', error_msg = error_msg, user_name = user_name, song_url = "{}_user_{}_id_{}".format(song_name, user_name, song_id), song = song_name, artist = artist, genre = genre, descr = descr, is_logged = logged_in > 0, logged_url = logged_url, user_url = user_url, logged_admin = logged_admin)
    
@app.route('/accounts/<user_name>_admin_<is_admin>', methods=['GET', 'POST'])
def accounts(user_name, is_admin):
    if not check_logged_in(user_name, is_admin): return redirect(url_for("home"))
    user_id = db.callFunction("select get_user_id(%s) as id", user_name).results[2][0]['id']
    if request.method == 'POST':
        r = request.form
        if "is_admin" in r:
            u_name = [u for u in list(r.keys()) if r[u] == "OK"][0]
            a = r["is_admin"]
            if a == "YES":
                db.callProcedure("select get_admin_name(admin_id) from admins where user_id = %s", 'set_admin', u_name)
            elif a == "NO":
                db.remove_admin(u_name)
        elif "search" in r:
            user = r["search_user"].strip()
            admin = r["search_admin"].strip()
            args, res, n, k = ([], (user, admin), [], ("User", "Admin"))
            for i, v in enumerate(res):
                if v != "" and v != "ALL": 
                    n.append(k[i] + " like %s")
                    args.append("%{}%".format(v))
            if len(args) > 0:
                q = " and ".join(n)
                q = "select * from table_users where " + q
                search_table("users")
                columns, rows = db.setArgs(*args).query(q).results[1:]
                return render_template('accounts.html', columns = columns, rows = rows, user_id = user_id, user_url = get_user_url(user_name, is_admin), res = res)
        elif "order" in list(r.keys())[0]:
            order = list(r.keys())[0]
            order = str(order).lower().replace("order_", "")
            o = db.set_order_accounts(order).results[2][0][order]
            order = order.capitalize()
            search_table("users")
            columns, rows = db.query("select * from table_users order by {} {}".format(order, o)).results[1:]
            res = db.query("select * from search_accounts where user_id = get_user_id_logged_in()").results[2]
            res = [list(r.values()) for r in res]
            return render_template('accounts.html', columns = columns, rows = rows, user_id = user_id, user_url = get_user_url(user_name, is_admin), res = res[1:])
        else:
            db.delete_user(list(r.keys())[0])
    search_table("users")
    columns, rows = db.query("select * from view_users").results[1:]
    res = db.query("select * from search_accounts where user_id = get_user_id_logged_in()").results[2]
    res = [list(r.values()) for r in res]
    return render_template('accounts.html', columns = columns, rows = rows, user_id = user_id, user_url = get_user_url(user_name, is_admin), res = res[1:])

if __name__ == '__main__':
    app.run(debug=True, use_reloader=True)
