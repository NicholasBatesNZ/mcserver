aws s3 cp s3://mcserver-rawfiles/plugins/ plugins/ --recursive

java -Xmx${MAX_HEAP} -jar server.jar --nogui