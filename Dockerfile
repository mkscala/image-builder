FROM dockerfile/nodejs

RUN apt-get update && \
    apt-get install -y apt-transport-https && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9 && \
    echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y lxc-docker-1.3.1 && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir $HOME/.ssh
RUN ssh-keyscan -H -p 22 github.com >> $HOME/.ssh/known_hosts

VOLUME /cache
ADD ./lib/ /source

WORKDIR /source
RUN chmod +x ./dockerBuild.sh
RUN npm install
CMD ["./dockerBuild.sh"]
