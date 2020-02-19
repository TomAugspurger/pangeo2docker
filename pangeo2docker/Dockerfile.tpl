FROM ubuntu:bionic
# ------ apt ------
RUN apt-get update && apt-get install -y \
  wget {{ apt }} \
 && rm -rf /var/lib/apt/lists/*

ARG NB_USER=jovyan
ARG NB_UID=1000
ARG REPO_DIR=repo
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}
ENV REPO_DIR ${HOME}/${REPO_DIR}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

USER ${NB_USER}
WORKDIR /home/${NB_USER}

# ------ conda ------

RUN wget -O conda -q https://repo.anaconda.com/pkgs/misc/conda-execs/conda-latest-linux-64.exe \
 && chmod +x conda \
 && ./conda config --add channels conda-forge \
 && ./conda config --set channel_priority strict

RUN ./conda create -n notebook \
  {{ conda_packages }} \
 && ./conda clean -afy \
 && find ${HOME}/.conda/ -follow -type f -name '*.a' -delete \
 && find ${HOME}/.conda/ -follow -type f -name '*.pyc' -delete \
 && find ${HOME}/.conda/ -follow -type f -name '*.js.map' -delete \
 && find ${HOME}/.conda/envs/notebook/lib/python*/site-packages/bokeh/server/static -follow -type f -name '*.js' ! -name '*.min.js' -delete

ENV KERNEL_PYTHON_PREFIX ${HOME}/.conda/envs/notebook
# simulate conda activate
ENV CONDA_EXE=${HOME}/conda
ENV PATH="${HOME}/.conda/envs/notebook/bin:${PATH}"

COPY --chown=${NB_USER}:${NB_USER} . ${REPO_DIR}

WORKDIR ${REPO_DIR}

# ------ postbuild ------
# Make sure that postBuild scripts are marked executable before executing them
RUN chmod +x binder/postBuild
RUN ./binder/postBuild

EXPOSE 8888

COPY repo2docker-entrypoint /usr/local/bin/repo2docker-entrypoint
 # Add start script
# RUN chmod +x "${REPO_DIR}/binder/start"
# ENV R2D_ENTRYPOINT "${REPO_DIR}/binder/start"
#  Add entrypoint
ENTRYPOINT ["/usr/local/bin/repo2docker-entrypoint"]

# Specify the default command to run
CMD ["jupyter", "notebook", "--ip", "0.0.0.0"]
