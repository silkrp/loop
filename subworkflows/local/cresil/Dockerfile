FROM continuumio/miniconda3

# docker build --platform linux/amd64 -t rpsilk/cresil:latest .
# docker push rpsilk/cresil:latest
# singularity pull docker://rpsilk/cresil

COPY environment.yml /tmp/environment.yml
RUN conda env create -f /tmp/environment.yml

SHELL ["bash", "-c"]
ENV PATH=/opt/conda/envs/cresil/bin:$PATH
RUN echo "conda activate cresil" >> ~/.bashrc

CMD ["/bin/bash"]