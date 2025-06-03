FROM ubuntu:18.04

SHELL ["/bin/bash", "-c"]
RUN apt-get update
RUN apt-get install -y sudo wget tar unzip pandoc python-setuptools python-pip python-dev python-virtualenv git build-essential software-properties-common python3-pip

# Install solidity
RUN wget https://github.com/ethereum/solidity/releases/download/v0.4.26/solc-static-linux && chmod +x solc-static-linux && mv solc-static-linux /usr/local/bin/solc
# Install z3
RUN wget https://github.com/Z3Prover/z3/archive/Z3-4.8.5.zip && unzip Z3-4.8.5.zip && rm Z3-4.8.5.zip && cd z3-Z3-4.8.5 && python scripts/mk_make.py --python && cd build && make && sudo make install && cd ../.. && rm -r z3-Z3-4.8.5

WORKDIR /root
RUN pip3 install cython
RUN pip3 install cytoolz
COPY fuzzer fuzzer
RUN cd fuzzer && pip3 install -r requirements.txt
RUN apt-get update && apt-get install -y jq && rm -rf /var/lib/apt/lists/*
COPY dataset dataset
COPY run.sh run.sh
COPY parse.sh parse.sh
COPY batch.sh batch.sh

