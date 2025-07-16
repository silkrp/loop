FROM continuumio/miniconda
#WORKDIR /usr/src/app

# docker build --platform linux/amd64,linux/arm64 -t rpsilk/wakhan:latest .
# docker push rpsilk/wakhan:latest
# singularity pull docker://rpsilk/wakhan


singularity pull docker://mkolmogo/wakhan:dev_c717baa

RUN git clone https://github.com/KolmogorovLab/Wakhan.git && \
    cd Wakhan/ && \
    conda env create -f environment.yml -n Wakhan

# Make RUN commands use the new environment:
SHELL ["conda", "run", "-n", "Wakhan", "/bin/bash", "-c"]

EXPOSE 5003
# The code to run when container is started:
ENTRYPOINT ["conda", "run", "-n", "Wakhan", "python3", "src/server.py"]