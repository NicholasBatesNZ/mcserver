FROM eclipse-temurin:17-jre-jammy

ENV MAX_HEAP "2G"

WORKDIR /mcserver

COPY . .

EXPOSE 25565
EXPOSE 25575

CMD java -Xmx${MAX_HEAP} -jar server.jar --nogui