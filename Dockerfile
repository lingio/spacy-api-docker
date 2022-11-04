FROM python:3.6
LABEL maintainer="gontrum@me.com"
LABEL version="0.2"
LABEL description="Base image, containing no language models."

# Install the required packages
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    supervisor \
    curl \
    nginx && \
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Install node for the frontend
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
  apt-get install -y nodejs &&\
  apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

COPY ./build_sassc.sh /app/build_sassc.sh

# Build SASSC
RUN bash /app/build_sassc.sh

# Copy and set up the app
COPY . /app

# Build app
RUN cd /app/frontend && make clean && make
RUN cd /app && make clean && make

RUN groupadd -g 3000 nonroot && useradd -M -u 1000 -g 3000 nonroot
RUN chmod g+wx /var/log/ && \
    chmod g+wx /opt/local/ && \
    usermod -aG adm nonroot

# Configure nginx & supervisor
RUN mv /app/config/nginx.conf /etc/nginx/sites-available/default &&\
  echo "daemon off;" >> /etc/nginx/nginx.conf && \
  mv /app/config/supervisor.conf /etc/supervisor/conf.d/

USER nonroot # drop root here
ENV PORT 80
EXPOSE 80
CMD ["bash", "/app/start.sh"]
