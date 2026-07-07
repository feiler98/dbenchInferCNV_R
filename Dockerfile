FROM fedora:42

RUN mkdir -p /scratch/tmp/feiler/dbenchInferCNV_R
WORKDIR /scratch/tmp/feiler/dbenchInferCNV_R
COPY . .

RUN dnf update -y && \
    dnf install -y \
        R-core \
        R-core-devel \
        R-devel \
        R-testthat \
        gcc \
        gcc-c++ \
        gcc-gfortran \
        make \
        wget \
        libxml2-devel \
        openssl-devel \
        libcurl-devel \
        gsl-devel \
        harfbuzz-devel \
        fribidi-devel \
        freetype-devel \
        libpng-devel \
        libtiff-devel \
        libjpeg-turbo-devel \
        git \
    && dnf clean all

RUN yum install -y curl libcurl-devel openssl openssl-devel
RUN yum install -y python3 python3-pip python3-devel
RUN pip install --no-cache-dir -r requirements.txt

RUN sudo dnf -y install lapack lapack-devel
RUN cd JAGS-4.3.2 && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf JAGS-4.3.2*

RUN R -e "install.packages('BiocManager', repos='https://cloud.r-project.org')"
RUN R -e "options(repos = c(CRAN = 'https://r-project.org')); \
    install.packages(c('rjags', 'gplots'), dependencies=TRUE)"
RUN R -e "library(rjags)" # verfication jags
RUN R -e "BiocManager::install('infercnv', ask=FALSE, update=TRUE)"
RUN R -e "library(infercnv)" # verification infercnv

CMD ["python3", "/scratch/tmp/feiler/dbenchInferCNV_R/run_infercnv.py"]
