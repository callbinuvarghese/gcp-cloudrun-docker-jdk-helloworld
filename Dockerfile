FROM adoptopenjdk:8-jre-hotspot

COPY target/helloworld.jar /helloworld.jar

ENTRYPOINT java -jar helloworld.jar
