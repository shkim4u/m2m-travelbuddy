FROM tomcat:7.0.73-jre8-alpine
LABEL maintainer "sanghyou"

# Parameters.
ARG MY_FILES_DIR=files
ARG TMP_DIR=/root/mytemp
ARG TOMCAT_DIR=/usr/local/tomcat

# Create temp dir for needed files
RUN mkdir $TMP_DIR/
COPY $MY_FILES_DIR/* $TMP_DIR/

# Clear out "default" apps that tomcat includes.
# Put Riches WAR file in webapps dir.
# Setup for appdefender agent.
#RUN rm -rf $TOMCAT_DIR/webapps/* && \
#	mv $TMP_DIR/riches.war $TOMCAT_DIR/webapps && \
#	tar -xvf $TMP_DIR/$APPDEF_AGENT_TAR -C $TOMCAT_DIR/ && \
#	mv $APPDEF_AGENT/ AppDefender && \
#	mkdir $TOMCAT_DIR/AppDefender/log && \
#	sed -i '2641\ #AppDefender Agent installation for Riches' $TOMCAT_DIR/bin/catalina.sh && \
#	sed -i '2641\ \CATALINA_OPTS=" -javaagent:$CATALINA_HOME/AppDefender/lib.latest/FortifyAgent.jar $CATALINA_OPTS"' $TOMCAT_DIR/bin/catalina.sh

RUN rm -rf $TOMCAT_DIR/webapps/* && \
	mv $TMP_DIR/riches.war $TOMCAT_DIR/webapps

# Clean up the temp dir.
RUN rm -rf $TMP_DIR
