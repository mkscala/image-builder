# Docker Image Builder

A Docker image that is used to build other Docker images using other resources.

## Building the Docker Image

To build the image, from the repository root:

```
docker build -t runnable/image-builder .
```

## Building an Image

This builds an image from the following resources:

- Dockerfile (stored on S3, versioned)
- Source directory (on S3, with versions)
- Repository:
  - From Github private repo - using a deploy key
  - From Github public repo - using https

Building an image with this image is a simple as using `docker run` and setting up environment variables in the command. An example script is included (`example.sh`), the contents of which are here (with some notes on each below):

```
docker run \
  -e RUNNABLE_AWS_ACCESS_KEY='AWS-ACCESS-KEY' \
  -e RUNNABLE_AWS_SECRET_KEY='AWS-SECRET-KEY'  \
  -e RUNNABLE_FILES_BUCKET='aws.bucket.name'  \
  -e RUNNABLE_PREFIX='source/' \
  -e RUNNABLE_FILES='{ "source/Dockerfile": "Po.EGeNr9HirlSJVMSxpf1gaWa5KruPa" }'  \
  -e RUNNABLE_KEYS_BUCKET='runnable.deploykeys'  \
  -e RUNNABLE_DEPLOYKEY='path/to/a/id_rsa'  \
  -e RUNNABLE_REPO='https://github.com/visionmedia/express'  \
  -e RUNNABLE_COMMITISH='master'  \
  -e RUNNABLE_DOCKER='tcp://192.168.59.103:2375' \
  -e RUNNABLE_DOCKERTAG='docker-tag' \
  -e RUNNABLE_DOCKER_BUILDOPTIONS='' \
  runnable/image-builder
```

- `RUNNABLE_AWS_ACCESS_KEY`: your AWS access key
- `RUNNABLE_AWS_SECRET_KEY`: your AWS secret access key
- `RUNNABLE_FILES_BUCKET`: bucket where the Dockerfile/source files are stored
- `RUNNABLE_PREFIX`: prefix of the source path of the files in S3
- `RUNNABLE_FILES`: a string representing a JSON object with S3 `Key`: `VersionId`. This MUST include a Dockerfile, and optionally can contain other files for the source directory
- `RUNNABLE_KEYS_BUCKET`: for a private repository, this is the bucket where deploy keys are stored
- `RUNNABLE_REPO`: repository to checkout using `git`.
- `RUNNABLE_COMMITISH`: something to checkout in the repository
- `RUNNABLE_DOCKER`: Docker connection information, best formatted `tcp://ipaddress:port`
- `RUNNABLE_DOCKERTAG`: Tag for the built Docker image
- `RUNNABLE_DOCKER_BUILDOPTIONS`: other Docker build options

## Multiple Repositories

This supports checking out multiple repositories, with multiple commitishes, and deploy keys. Set the variable using `;` as the separator and it will download all of them. 

The following variables support multiple values:

- `RUNNABLE_DEPLOYKEY`
- `RUNNABLE_REPO`
- `RUNNABLE_COMMITISH`

NOTE: `RUNNABLE_REPO` and `RUNNABLE_COMMITISH` need to be a one-to-one correspondence for it to work correctly (does NOT assume `master` or any other value).


## Debugging the Builder

If you need to debug the builder, you can set the environment variables, then additionally set `--rm -ti` as `run` options, and put `bash` on the end of the command after `runnable/image-builder`. This will dump you into a shell where you can run `./dockerBuild.sh` to manually run the build!
