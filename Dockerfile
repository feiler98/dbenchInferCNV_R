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
        blas-devel \
        lapack-devel \
        lapack \
    && dnf clean all

RUN yum install -y curl libcurl-devel openssl openssl-devel
RUN yum install -y python3 python3-pip python3-devel
RUN pip install --no-cache-dir -r requirements.txt

RUN wget -O /tmp/jags.tar.gz https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Source/JAGS-4.3.2.tar.gz/download \
    && cd /tmp \
    && tar -xf jags.tar.gz \
    && cd JAGS-4.3.2 \
    && ./configure --libdir=/usr/local/lib64 \
    && make \
    && sudo make install



# rjags
RUN R -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); install.packages('remotes')"

RUN R -e "library(remotes)"  # verfication remotes
RUN R -e "remotes::install_url('https://cloud.r-project.org/src/contrib/rjags_4-17.tar.gz')"
RUN R -e "library(rjags)"  # verfication jags

RUN R -e "install.packages('BiocManager', repos='https://cloud.r-project.org')"
RUN R -e "install.packages('gplots', repos='https://cloud.r-project.org')"
RUN R -e "BiocManager::install('infercnv', ask=FALSE, update=TRUE)"
RUN R -e "library(infercnv)"  # verification infercnv

CMD ["python3", "/scratch/tmp/feiler/dbenchInferCNV_R/run_infercnv.py"]
