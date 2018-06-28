FROM cucloudcollab/xvfb-firefox

LABEL maintainer="Dom DePasquale <dad264@psu.edu>, Andy Cobaugh <atc135@psu.edu>"

RUN apt-get update && \
  apt-get upgrade --no-install-recommends -y && \
  apt-get install --no-install-recommends -y \
    zlib1g-dev \
    ruby \
    ruby-dev && \
    rm -rf /var/lib/apt/lists/*

RUN gem install selenium-webdriver \
  aws-sdk \
  highline \
  parseconfig \
  json \
  ruby-saml

COPY bin/ /opt

ENTRYPOINT ["/opt/start-saml-api.sh"]
