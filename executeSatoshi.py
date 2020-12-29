from pySql import SatoshiSqlAccess

if __name__ == "__main__":
    db = SatoshiSqlAccess(True)
    db.source("creates.sql", printText = False)
    db.source("triggers.sql", printText = False)
    db.source("prepared_insert_statements.sql", printText = False)
    db.source("gets.sql", printText = False)
    db.source("adds.sql", printText = False)
    db.source("views.sql", printText = False)
    db.close()