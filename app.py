import web

urls = ("/", "test")

app = web.application(urls, globals(), autoreload=False)

class test:
    def GET(self):
        return "Hello World new"

if __name__ == "__main__":
    app.run()
else:
    application = app.wsgifunc()