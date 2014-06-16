FROM dockerfile/nodejs

RUN apt-get update
RUN apt-get install -y docker.io
RUN ln -s `which docker.io` /usr/bin/docker

RUN mkdir $HOME/.ssh
RUN ssh-keyscan -H github.com > $HOME/.ssh/known_hosts

ADD ./ /source

WORKDIR /source
RUN chmod +x ./dockerBuild.sh
RUN npm install aws-sdk mkdirp async uuid minimist
CMD ["./dockerBuild.sh"]
