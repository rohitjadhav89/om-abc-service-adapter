FROM hansentech.jfrog.io/ordermgmt-docker-releases/sigma_external/ubi-java:ubi8.8-1067.1698056881-openjdk17.0.9_9-LTS-Jgit5.0
LABEL Maintainer="Hansen Technologies"
ARG SERVICE_NAME
LABEL Service=$SERVICE_NAME

ARG UNAME=omuser
ARG UID=1001
ARG GID=1001

ENV JAVA_OPTS ""

RUN groupadd -g $GID -o $UNAME && \
    useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME  && \
    mkdir -p /home/application/config

RUN chown -R $UNAME:$UNAME /home/application
USER $UNAME

COPY adapter-conf/ /home/application/adapter-conf/

WORKDIR /home/application/

# To utilize the concept of caching, placing entrypoint before Jar Name as entrypoint will not change
ENTRYPOINT ["/bin/bash", "-c", "java $JAVA_OPTS -jar $JAR_NAME"]

ARG JAR_NAME
ENV JAR_NAME $JAR_NAME

ARG JAR_PATH
ADD $JAR_PATH /home/application/
#COPY target/classes/META-INF /home/application/licenses