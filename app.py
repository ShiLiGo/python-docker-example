# coding=utf8
import web
import redis

#用户DB的配置
USERDB_HOST = "db"
USERDB_PORT = 3306
USERDB_USER = "duoletest"
USERDB_PASS = "123456"
USERDB_DATABASE = "duole"

udb = web.database(
    dbn = "mysql",
    host = USERDB_HOST,
    port = USERDB_PORT,
    user = USERDB_USER,
    pw = USERDB_PASS,
    db = USERDB_DATABASE,
)

# userredis配置
USERREDIS_HOST = "redis"
USERREDIS_PORT = 6379
USERREDIS_PWD = ""

ursc = redis.StrictRedis(
    host = USERREDIS_HOST,
    port = USERREDIS_PORT,
    password = USERREDIS_PWD,
    socket_timeout = 10,
    socket_connect_timeout = 10,
)

urls = ("/", "test")

app = web.application(urls, globals(), autoreload=False)

class test:
    def GET(self):
        try:
            ursc.incr("testincr", 1)
            t = ursc.get("testincr")
            print 'test, t', t
            user = udb.query("select * from purchaseblacklist where content = '70622'")
            if not user:
                udb.query("insert into purchaseblacklist(id, type, content, gameid, createtime) values(NULL, 5, '70622', 3, NOW())")
            else:
                r = user[0]
                print 'user', r
        except Exception as e:
            print(e)
            return "query exception"
        return "Hello World new"

if __name__ == "__main__":
    app.run()
else:
    application = app.wsgifunc()