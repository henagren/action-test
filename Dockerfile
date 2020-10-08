FROM maven:3.6-openjdk-14-slim AS build
RUN mkdir -p /workspace
WORKDIR /workspace
COPY pom.xml /workspace
COPY src /workspace/src

RUN mvn -B -f pom.xml clean package -DskipTests 



FROM openjdk:14-slim
COPY --from=build /workspace/target/*.jar /usr/local/bin/app.jar

# setup SSH with username/password access
RUN apt-get update \
    && apt-get install -y openssh-server \
    && mkdir -p /var/run/sshd 
	
RUN echo 'root:password123' | chpasswd
RUN sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile


EXPOSE 22

RUN apt install -y dos2unix supervisor \
	&& mkdir -p /var/log/supervisor
	
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN dos2unix /etc/supervisor/conf.d/supervisord.conf
RUN chmod +x /etc/supervisor/conf.d/supervisord.conf


CMD ["/usr/bin/supervisord"]

