## Simple python docker dev example for the official docker docs
https://docs.docker.com/language/python/containerize/


## mysql指定 database 后，再进行查询，报Access denied for user 'root'@'172.18.0.4'
When you start the mysql image, you can adjust the configuration of the MySQL instance by passing one or more environment variables on the docker run command line. Do note that none of the variables below will have any effect if you start the container with a data directory that already contains a database: any pre-existing database will always be left untouched on container startup.
解决方案：通过访问 mysql 容器挂在的目录，清空，再次启动容器