FROM fedora:42

RUN sudo dnf -y update && \
    sudo dnf -y install \
    gsl-devel \
    fftw-devel \
    R-core \
    R-devel \
    R-core-devel \
    R-testthat \
    gcc \
    gcc-c++ \
    make \
    wget \
    blas-devel \
    lapack-devel \
    lapack \
    curl \
    libcurl-devel \
    openssl \
    openssl-devel \
    libxml2-devel \
    pkgconf \
    freetype-devel \
    udunits2-devel \
    fontconfig-devel \
    harfbuzz-devel \
    fribidi-devel \
    abseil-cpp-devel \
    libtiff-devel \
    libarrow \
    libarrow-devel \
    gcc-gfortran \
    libcurl-devel \
    glpk \
    hdf5-devel \
    glpk-devel \
    stats-collect \
    R-fs \
    R-sass \
    R-markdown \
    R-XVector \
    R-doParallel \
    R-png \
    R-MatrixGenerics \
    R-markdown \
    R-shiny \
    R-IRanges-devel \
    R-abind \
    R-S4Vectors \
    R-matrixStats \
    libpng-devel \
    libjpeg-turbo-devel \
    gawk && \
    dnf clean all

RUN wget -O /tmp/jags.tar.gz https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Source/JAGS-4.3.2.tar.gz/download \
	&& cd /tmp \
	&& tar -xvf jags.tar.gz \
	&& cd /tmp/JAGS-4.3.2 \
	&& ./configure --libdir=/usr/local/lib64 \
	&& make \
	&& sudo make install

RUN echo "/usr/local/lib" >> /etc/ld.so.conf.d/jags.conf && \
    echo "/usr/local/lib64" >> /etc/ld.so.conf.d/jags.conf && \
    ldconfig

# rjags
RUN R -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); install.packages('remotes')"

RUN R -e "library(remotes)"  # verfication remotes
RUN R -e "remotes::install_url('https://cloud.r-project.org/src/contrib/rjags_4-17.tar.gz')"
RUN R -e "library(rjags)"

RUN mkdir -p /scratch/tmp/feiler/dbenchInferCNV_R
WORKDIR /scratch/tmp/feiler/dbenchInferCNV_R
COPY . .
RUN R -e "install.packages('BiocManager', repos='https://cloud.r-project.org', Ncpus=20)"
RUN R -e "install.packages('gplots', repos='https://cloud.r-project.org', Ncpus=20)"
RUN Rscript script_install.R

RUN dnf install -y python3 python3-pip python3-devel
RUN pip install --no-cache-dir -r requirements.txt

#RUN R -e "BiocManager::install('infercnv', ask=FALSE, update=TRUE)"
#RUN R -e "library(infercnv)"  # verification infercnv

CMD ["python3", "/scratch/tmp/feiler/dbenchInferCNV_R/run_infercnv.py"]
