FROM eclipse-temurin:17-jre-jammy

ENV MAX_HEAP "14G"

COPY . .

EXPOSE 25565

CMD java -Xmx${MAX_HEAP} -jar server.jar --nogui