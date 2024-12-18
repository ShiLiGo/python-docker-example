# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/engine/reference/builder/

ARG PYTHON_VERSION=2.7.14
# FROM oryxprod/python-2.7:20190521.9 as base
FROM centos:centos7.4.1708 as base
# FROM python:${PYTHON_VERSION}-slim as base

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
ARG UID=10001
RUN useradd \
    --no-create-home \
    --home-dir /nonexistent \
    --shell /sbin/nologin \
    --uid "${UID}" \
    appuser
RUN passwd -d appuser

# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.cache/pip to speed up subsequent builds.
# Leverage a bind mount to requirements.txt to avoid having to copy them into
# into this layer.
RUN --mount=type=bind,source=Centos-7.repo,target=Centos-7.repo \
    cp Centos-7.repo /etc/yum.repos.d/CentOS-Base.repo
RUN yum install -y epel-release
RUN yum install -y python-devel mysql-devel gcc
RUN --mount=type=cache,target=/root/.cache/pip \
    curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py
RUN --mount=type=cache,target=/root/.cache \
    python get-pip.py
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && pip install --upgrade setuptools==44.1.1 && pip install --upgrade wheel
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install virtualenv==16.7.9
    # TODO: Install any other dependencies.
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=bind,source=requirements.txt,target=requirements.txt \
    virtualenv -p python /app/venv  && \
    . /app/venv/bin/activate && \
    pip install --upgrade setuptools==44.1.1 && \
    pip install --upgrade wheel && \
    python -m pip install -r requirements.txt
RUN --mount=type=bind,source=uwsgi-2.0.18-8.el7.x86_64.rpm,target=uwsgi-2.0.18-8.el7.x86_64.rpm \
    yum localinstall -y uwsgi-2.0.18-8.el7.x86_64.rpm
RUN --mount=type=bind,source=nginx-1.20.1-10.el7.x86_64.rpm,target=nginx-1.20.1-10.el7.x86_64.rpm \
    yum install -y nginx-1.20.1-10.el7.x86_64.rpm
RUN yum install -y uwsgi-plugin-python

# Switch to the non-privileged user to run the application.
# USER appuser
USER root

# Copy the source code into the container.
COPY . .
RUN cp uwsgi.ini /etc/uwsgi.ini
RUN mkdir -p /run/uwsgi && chmod 777 /run/uwsgi && chown uwsgi:uwsgi /run/uwsgi
RUN cd /var/log && mkdir -p /var/log/uwsgi && chmod 777 /var/log/uwsgi
RUN cp pingtai-sdk.conf /etc/nginx/conf.d/pingtai-sdk.conf
RUN cp pingtai-sdk.ini /etc/uwsgi.d/pingtai-sdk.ini
# RUN cp enc_req_resp.js /etc/nginx/enc_req_resp.js
RUN cp enc_import.conf /etc/nginx/enc_import.conf
RUN cp enc_location.conf /etc/nginx/enc_location.conf
RUN cp nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /var/www && chmod 777 /var/www
RUN mkdir -p /var/www/apps && chmod 777 /var/www/apps
RUN mkdir -p /var/www/apps/duole && chmod 777 /var/www/apps/duole
RUN mkdir -p /var/www/apps/duole/log && chmod 777 /var/www/apps/duole/log
RUN cp -r app/duole_usdk_server/* /var/www/apps/duole

# Expose the port that the application listens on.
EXPOSE 9005

# Run the application.
CMD sh start-service.sh