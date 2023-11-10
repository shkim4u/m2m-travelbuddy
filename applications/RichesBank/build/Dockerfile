# 애플리케이션 빌드 스테이지
#FROM maven:3.3.9-jdk-8 AS build
FROM public.ecr.aws/docker/library/maven:3.9.4-amazoncorretto-11 AS build
WORKDIR /app

# 빌드 성능 개선
COPY pom.xml .
COPY local-libs-repository /app/local-libs-repository
COPY rulesets /app/rulesets

COPY src ./src
RUN mvn -f pom.xml -q clean compile spotbugs:spotbugs package

# 컨테이너 이미지 빌드 스테이지
# 하지만 아래 소스 이미지가 최선일까요?
#FROM tomcat:9-jdk11
FROM public.ecr.aws/docker/library/tomcat:9.0-jre11

RUN locale-gen ko_KR.UTF-8
ENV LC_ALL ko_KR.UTF-8

COPY --from=build /app/target/\*.war /usr/local/tomcat/webapps/riches.war
# (Optional) Make the "/riches/" path to root "/" with root healthcheck.
#COPY --from=build /app/target/\*.war /usr/local/tomcat/webapps/ROOT.war

# SpotBugs output files: XML and SARIF
COPY --from=build /app/target/spotbugsXml.xml /usr/local/tomcat/webapps/spotbugs-xml.xml
COPY --from=build /app/target/spotbugsSarif.json /usr/local/tomcat/webapps/spotbugs-sarif.json

EXPOSE 8080

CMD ["catalina.sh", "run"]
