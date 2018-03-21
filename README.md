# Docker Zeppelin CONTAINER
[![Build Status](https://travis-ci.org/yabhinav/docker-zeppelin.svg?branch=master)](https://travis-ci.org/yabhinav/docker-zeppelin)
[![Deploy to Docker Cloud](https://files.cloud.docker.com/images/deploy-to-dockercloud.svg)](https://cloud.docker.com/stack/deploy/?repo=https://github.com/yabhinav/docker-zeppelin)

## Overview
This docker image provides a Zeppelin server with supported Interpreters like `spark`,`python`,`md` etc..  

The repository [yabhinav/zeppelin](https://hub.docker.com/r/yabhinav/zeppelin/) contains Dockerized Zeppelin Container images, published to the public Docker Hub via automated build mechanism. I use it to evaluate independently spark code in a more convenient way than a `spark-shell`.

## OS Configuration
These are Docker images for are build on top latest [Debian](https://hub.docker.com/_/debian/) container.

This Docker container contains a full Hadoop distribution with the following components:

* Oracle JDK 8
* Zeppelin 0.7.3
* Spark 2.2.0
* Miniconda Datascience toolkit (R and python)

## Images and Tags

### Tags and Variants

You can use the following tag to pull latest zeppelin server with all interpreters installed:
- [`all` (*all/Dockerfile*)](https://github.com/yabhinav/docker-zeppelin/blob/master/all/Dockerfile)

The image has 2 variations:  `minimal`, and `all`.

* `minimal`: it includes the interpreters less than 50MB: `angular,python,shell,bigquery,file,jdbc,kylin,livy,md,postgresql,cassandra,elasticsearch`

* `all`: It includes all the interpreters, so beside the interpreters listed above, the following interpreters are also included: `alluxio,ignite,lens,beam,hbase,pig,scio`

Variants of the following tags available with zeppelin release versions:
- [`minimal` (*base/Dockerfile*)](https://github.com/yabhinav/docker-zeppelin/blob/master/minimal/Dockerfile)
- [`latest` (*all/Dockerfile*)](https://github.com/yabhinav/docker-zeppelin/blob/master/all/Dockerfile)

### Pull Images

For example for Zeppelin version - 0.7.3, You can pull the following images from release tags :

``` bash
$ docker pull yabhinav/zeppelin:0.7.3-all
$ docker pull yabhinav/zeppelin:0.7.3-minimal
```

You can pull the latest image with all interpreters with command :

``` bash
$ docker pull yabhinav/zeppelin:latest
```


### Start the container

All data are stored in `/zeppelin` directory, such as:

* `ZEPPELIN_LOG_DIR`: `/zeppelin/log`
* `ZEPPELIN_PID_DIR`: `/zeppelin/run`
* `ZEPPELIN_NOTEBOOK_DIR`: `/zeppelin/notebook`

So, to persistent the data, a docker volume should be used to mount on the `/zeppelin` directory.
```bash
$ docker volume create zeppelin-data
$ docker volume ls | grep zeppelin-data
$ docker run -d --name zeppelin -p 8080:8080 -p 4040:4040 -v zeppelin-data:/data yabhinav/zeppelin:latest
```

> If you want to mount `/data` to host directory, instead of docker volume, please note, the directory's owner uid is `501`, which is user `zeppelin` inside the container.

```bash
$ docker run -d --name zeppelin -p 8080:8080 -p 4040:4040 -v ~/Downloads/zeppelin-data:/data yabhinav/zeppelin:latest
```


### Docker Compose
It's recommended to use `docker-compose` for the service, an example `docker-compose.yml` is provided for this purpose.

From your project directory, type docker-compose up to start the Zeppelin container
```bash
$ docker-compose up
```

If you want to run your services in the background, you can pass the -d flag (for “detached” mode) to docker-compose up and use docker-compose ps to see what is currently running:
```bash
$  docker-compose up -d
Creating network "dockerzeppelin_default" with the default driver
Creating volume "dockerzeppelin_zeppelin-data" with default driver
Creating dockerzeppelin_zeppelin_1 ... done
$  docker-compose ps
         Name                         Command               State                       Ports
-------------------------------------------------------------------------------------------------------------------
dockerzeppelin_zeppelin_1   /bin/sh -c ${ZEPPELIN_HOME ...   Up      0.0.0.0:4040->4040/tcp, 0.0.0.0:8080->8080/tcp}
```
If you started Compose with docker-compose up -d, stop your services once you’ve finished with them:
```bash
$ docker-compose stop
```

You can bring everything down, removing the containers entirely, with the down command. Pass --volumes to also remove the data volume used by the Redis container:
```bash
$ docker-compose down --volumes
```

## License

MIT / BSD


## Author Information

Created by [Abhinav Yalamanchili](https://yabhinav.github.com)
