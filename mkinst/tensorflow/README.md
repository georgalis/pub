# Bootstrap TensorFlow

###### TensorFlow bootstrap methods

Rough notes, journal of bootstrap iterations

## Dependencies

### Bazel

([Compiling Bazel from source](https://docs.bazel.build/versions/master/install-compile-source.html)

* [Releases](https://github.com/bazelbuild/bazel/releases)
  * [Bazel 0.29 release notes](https://blog.bazel.build/2019/08/27/bazel-0.29.0.html)
  * [Bazel bundled with OpenJDK](https://github.com/bazelbuild/bazel/releases)
    * [Bazel's OpenJDK Mirror](https://mirror.bazel.build/openjdk/azul-zulu12.2.3-ca-jdk12.0.1/zsrc12.2.3-jdk12.0.1.zip)
  * [bazel-0.29.1-dist.zip](https://github.com/bazelbuild/bazel/releases/download/0.29.1/bazel-0.29.1-dist.zip)
* Bazel prerequisites
  * C++ build toolchain, part of NetBSD full install
  * ` pkgin in bash zip unzip openjdk8 python37 `
* unpack the distribution archive
* enter the distribution directory, execute build:
  * expect to use ~750MB of memory, open ulimit in login shell and the (bash) compiling shell
```
ulimit -m unlimited && bash
ulimit -m unlimited
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" JAVA_HOME="/usr/pkg/java/openjdk8" bash ./compile.sh
```

NetBSD 8.1, on a VirtualBoxVM, on MacBookPro hardware, with cpp (nb3 20180905) 5.5.0.
My Bazel 29.1 build is failing with cc_toolchain_suite 'unknown' cpu detected.
* https://github.com/bazelbuild/bazel/issues/9397#issuecomment-538454177
* https://groups.google.com/forum/#!topic/bazel-discuss/S8DrmgEvVyk


the Will files are binaries compiled for various OS/arch, x86_64 NetBSD is not one of them.
```
pkgin in pip3.7 python37 py37-numpy
pip3.7 install tensorflow
ERROR: No matching distribution found for tensorflow
```

docker service from installer ubuntu 18.04
docker run -it tensorflow/tensorflow bash




