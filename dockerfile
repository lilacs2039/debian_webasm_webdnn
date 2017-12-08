FROM debian:latest

MAINTAINER lilacs

ENV EMCC_SDK_VERSION 1.37.15
ENV EMCC_SDK_ARCH 32
ENV EMCC_BINARYEN_VERSION 1.37.14

WORKDIR /

RUN apt-get update && apt-get install -y --no-install-recommends gnupg ca-certificates build-essential cmake curl git-core openjdk-8-jre-headless python \
    && apt-mark hold openjdk-8-jre-headless \
    && apt-mark hold make \
    && curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    && apt-get install -y nodejs \
    && curl https://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-portable.tar.gz > emsdk-portable.tar.gz \
    && tar xzf emsdk-portable.tar.gz \
    && rm emsdk-portable.tar.gz \
    && cd emsdk-portable \
    && ./emsdk update \
    && ./emsdk install --build=MinSizeRel sdk-tag-$EMCC_SDK_VERSION-${EMCC_SDK_ARCH}bit \
    && ./emsdk install --build=MinSizeRel binaryen-tag-${EMCC_BINARYEN_VERSION}-${EMCC_SDK_ARCH}bit \
\
    && mkdir -p /clang \
    && cp -r /emsdk-portable/clang/tag-e$EMCC_SDK_VERSION/build_tag-e${EMCC_SDK_VERSION}_${EMCC_SDK_ARCH}/bin /clang \
    && mkdir -p /clang/src \
    && cp /emsdk-portable/clang/tag-e$EMCC_SDK_VERSION/src/emscripten-version.txt /clang/src/ \
    && mkdir -p /emscripten \
    && cp -r /emsdk-portable/emscripten/tag-$EMCC_SDK_VERSION/* /emscripten \
    && cp -r /emsdk-portable/emscripten/tag-${EMCC_SDK_VERSION}_${EMCC_SDK_ARCH}bit_optimizer/optimizer /emscripten/ \
    && mkdir -p /binaryen \
    && cp -r /emsdk-portable/binaryen/tag-${EMCC_BINARYEN_VERSION}_${EMCC_SDK_ARCH}bit_binaryen/* /binaryen \
    && echo "import os\nLLVM_ROOT='/clang/bin/'\nNODE_JS='nodejs'\nEMSCRIPTEN_ROOT='/emscripten'\nEMSCRIPTEN_NATIVE_OPTIMIZER='/emscripten/optimizer'\nSPIDERMONKEY_ENGINE = ''\nV8_ENGINE = ''\nTEMP_DIR = '/tmp'\nCOMPILER_ENGINE = NODE_JS\nJS_ENGINES = [NODE_JS]\nBINARYEN_ROOT = '/binaryen/'\n" > ~/.emscripten \
    && rm -rf /emsdk-portable \
    && rm -rf /emscripten/tests \
    && rm -rf /emscripten/site \
    && rm -rf /binaryen/src /binaryen/lib /binaryen/CMakeFiles \
    && for prog in em++ em-config emar emcc emconfigure emmake emranlib emrun emscons emcmake; do \
           ln -sf /emscripten/$prog /usr/local/bin; done \
    && apt-get -y --purge remove gnupg curl git-core build-essential gcc \
    && apt-get -y clean \
    && apt-get -y autoclean \
    && apt-get -y autoremove \
    && echo "Installed ... testing"
RUN emcc --version \
    && mkdir -p /tmp/emscripten_test && cd /tmp/emscripten_test \
    && printf '#include <iostream>\nint main(){std::cout<<"HELLO"<<std::endl;return 0;}' > test.cpp \
    && em++ -O2 test.cpp -o test.js && nodejs test.js \
    && em++ test.cpp -o test.js && nodejs test.js \
    && em++ -s WASM=1 test.cpp -o test.js && nodejs test.js \
    && cd / \
    && rm -rf /tmp/emscripten_test \
    && echo "All done."

VOLUME ["/src"]
WORKDIR /src

#--------------------------------------------------------------------------------------

USER root

RUN mv /bin/sh /bin/sh_tmp && ln -s /bin/bash /bin/sh

RUN apt-get update && \
	apt-get install -y git wget

RUN git clone --depth 1 https://github.com/pyenv/pyenv /root/.pyenv && \
	echo 'eval "$(pyenv init -)"' >> /root/.bashrc && \
	echo 'PYENV_ROOT="$HOME/.pyenv"' >> /root/.bashrc && \
	echo 'PATH="$PYENV_ROOT/bin:$PATH"' >> /root/.bashrc

# anacondaをメインのpythonに設定。
# activateがpyenvとanacondaでバッティングするので、pathに明示しておく。
RUN source /root/.bashrc && \
	pyenv install anaconda3-5.0.1 && \
	pyenv rehash && \
	pyenv global anaconda3-5.0.1 && \
	echo 'export PATH="$PYENV_ROOT/versions/anaconda3-5.0.1/bin/:$PATH"' >> /root/.bashrc && \
	source /root/.bashrc && \
	conda update conda && \
	conda create -n py36 python=3.6 && \
	pyenv local anaconda3-5.0.1/envs/py36


RUN source /root/.bashrc && \
	git clone --depth 1 https://github.com/mil-tokyo/webdnn /webdnn && \
	cd /webdnn && python3 setup.py install

#RUN cd / && \
#	wget http://bitbucket.org/eigen/eigen/get/3.3.3.tar.bz2 && \
#	tar jxf 3.3.3.tar.bz2 && \
#	rm 3.3.3.tar.bz2 && \
#	echo 'export CPLUS_INCLUDE_PATH=$PWD/eigen-eigen-67e894c6cd8f' >> /root/.bashrc

RUN source /root/.bashrc && \
	pip install chainer keras tensorflow 


RUN cd / && \
	wget http://bitbucket.org/eigen/eigen/get/3.3.3.tar.bz2 && \
	tar jxf 3.3.3.tar.bz2 && \
	echo 'export CPLUS_INCLUDE_PATH=/eigen-eigen-67e894c6cd8f' >> /root/.bashrc && \
	cd /usr/local/bin && \
	ln emcc emcc.py

RUN rm /bin/sh && mv /bin/sh_tmp /bin/sh

