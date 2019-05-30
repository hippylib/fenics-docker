# Builds a Docker image with FEniCS stable version built from
# git sources. The image is at:
#
#    https://quay.io/repository/fenicsproject/stable
#
# Authors:
# Jack S. Hale <jack.hale@uni.lu>

FROM quay.io/fenicsproject/dev-env:latest
MAINTAINER fenics-project <fenics-support@googlegroups.com>

USER root 

ENV FENICS_PYTHON=python3
ENV DOLFIN_VERSION="2019.1.0.post0"
ENV MSHR_VERSION="2019.1.0"
ENV PYPI_FENICS_VERSION=">=2019.1.0,<2019.2.0"

WORKDIR /tmp
COPY la.cpp.patch /tmp/la.cpp.patch
RUN /bin/bash -c "PIP_NO_CACHE_DIR=off ${FENICS_PYTHON} -m pip install 'fenics${PYPI_FENICS_VERSION}' && \
                  git clone https://bitbucket.org/fenics-project/dolfin.git && \
                  cd dolfin && \
                  git checkout ${DOLFIN_VERSION} && \
                  patch python/src/la.cpp < ../la.cpp.patch && \
                  mkdir build && \
                  cd build && \
                  cmake ../ && \
                  make && \
                  make install && \
                  mv /usr/local/share/dolfin/demo /tmp/demo && \
                  mkdir -p /usr/local/share/dolfin/demo && \
                  mv /tmp/demo /usr/local/share/dolfin/demo/cpp && \
                  cd ../python && \
                  PIP_NO_CACHE_DIR=off ${FENICS_PYTHON} -m pip install . && \
                  cd demo && \
                  python3 generate-demo-files.py && \
                  mkdir -p /usr/local/share/dolfin/demo/python && \
                  cp -r documented /usr/local/share/dolfin/demo/python && \
                  cp -r undocumented /usr/local/share/dolfin/demo/python"
RUN /bin/bash -c  "${FENICS_PYTHON} -m pip install meshio[all]" 
RUN /bin/bash -c  "cd /tmp/ && \
                  git clone https://bitbucket.org/fenics-project/mshr.git && \
                  cd mshr && \
                  git checkout ${MSHR_VERSION} && \
                  mkdir build && \
                  cd build && \
                  cmake ../ && \
                  make && \
                  make install && \
                  cd ../python && \
                  PIP_NO_CACHE_DIR=off ${FENICS_PYTHON} -m pip install . && \
                  ldconfig && \
                  rm -rf /tmp/*"
                  

# Install fenics as root user into /usr/local then remove the fenics-* scripts
# the fenics.env.conf file and the unnecessary /home/fenics/local directory as
# the user does not need them in the stable image!
RUN /bin/bash -c "cp -r /usr/local/share/dolfin/demo $FENICS_HOME/demo && \
                  rm -rf /home/fenics/local && \
                  rm -rf $FENICS_HOME/bin && \
                  echo '' >> $FENICS_HOME/.profile" 

USER fenics

RUN /bin/bash -c "mkdir -p /home/fenics/.local"

WORKDIR $FENICS_HOME

COPY WELCOME $FENICS_HOME/WELCOME

USER root
