FROM dockerfile/nodejs

RUN apt-get install -y apt-transport-https
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
RUN echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
RUN apt-get update
RUN apt-get install -y lxc-docker-1.0.0

RUN mkdir $HOME/.ssh
RUN ssh-keyscan -H github.com > $HOME/.ssh/known_hosts

ADD ./ /source

WORKDIR /source
RUN chmod +x ./dockerBuild.sh
RUN npm install aws-sdk mkdirp async uuid minimist
CMD ["./dockerBuild.sh"]
