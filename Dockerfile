FROM trinityctat/infercnv

RUN mkdir -p /scratch/tmp/feiler/dbenchInferCNV_R
WORKDIR /scratch/tmp/feiler/dbenchInferCNV_R
COPY . .

RUN apt update
RUN apt install -y python3 python3-pip
RUN apt install -y libreadline-dev
RUN apt install -y r-base r-base-dev python3-dev python-setuptools lzma-dev libblas-dev liblapack-dev
RUN pip3 install -r requirements.txt
RUN cd ..
RUN git clone https://github.com/rpy2/rpy2
RUN cd rpy2 && pip install .
RUN cd /scratch/tmp/feiler/dbenchInferCNV_R
RUN pip install -r requirements.txt

CMD ["python3", "/scratch/tmp/feiler/dbenchInferCNV_R/run_infercnv.py"]
