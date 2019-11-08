FROM ruby:2.6.2

RUN apt update && apt install -yq \
    sudo \
    cowsay \
    git \
    tmux \
    wget \
    zsh \
    vim \
    fonts-powerline \
    gitk \
    meld \
    tree \
    psmisc \
    mc \
    screen \
    locales \
    gnupg

RUN mkdir -p /home/developer/sharetribe

# ZSH config
RUN git clone https://github.com/robbyrussell/oh-my-zsh /opt/oh-my-zsh && \
    cp /opt/oh-my-zsh/templates/zshrc.zsh-template .zshrc && \
    cp -r /opt/oh-my-zsh .oh-my-zsh && \
    cp /opt/oh-my-zsh/templates/zshrc.zsh-template /home/developer/.zshrc && \
    cp -r /opt/oh-my-zsh /home/developer/.oh-my-zsh && \
    sed  "s/robbyrussell/bira/" -i /home/developer/.zshrc && \
    echo "PROMPT=\$(echo \$PROMPT | sed 's/%m/%f\$IMAGE_NAME/g')" >> /home/developer/.zshrc && \
    echo "RPROMPT=''" >> /home/developer/.zshrc

# Tmux config
WORKDIR /opt
RUN git clone https://github.com/gpakosz/.tmux.git && \
    echo "set-option -g default-shell /bin/zsh" >> .tmux/.tmux.conf
COPY on_startup/tmux_setup.sh /opt/startup/

# Sublime instalation
ARG SUBLIME_BUILD="${SUBLIME_BUILD:-3207}"
RUN wget --no-check-certificate  https://download.sublimetext.com/sublime-text_build-"${SUBLIME_BUILD}"_amd64.deb --no-check-certificate && \
    dpkg -i sublime-text_build-"${SUBLIME_BUILD}"_amd64.deb

RUN wget --no-check-certificate -qO - https://download.sublimetext.com/sublimehq-pub.gpg | apt-key add -
RUN echo "deb http://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
RUN apt update && apt install -y sublime-merge

### Install mysql tools
RUN apt-get install -y nginx mysql-client default-libmysqlclient-dev

# SSH setup
RUN apt update && apt install -yq \
    openssh-server
COPY on_startup/ssh_setup.sh /opt/startup/

### Installing nodejs nad npm

# gpg keys listed at https://github.com/nodejs/node#release-team
RUN set -ex \
  && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 10.15.3

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Install latest bundler
ENV BUNDLE_BIN=
RUN gem install bundler

RUN mkdir /opt/gem_folder

COPY Gemfile /opt/gem_folder
COPY Gemfile.lock /opt/gem_folder

WORKDIR /opt/gem_folder

RUN bundle install && \
    gem install foreman

ENV NODE_ENV production
ENV NPM_CONFIG_LOGLEVEL error
ENV NPM_CONFIG_PRODUCTION true

RUN npm install

RUN export PATH=$PATH:/opt/gem_folder/

RUN wget -q http://sphinxsearch.com/files/sphinx-3.0.2-2592786-linux-amd64.tar.gz && \
    tar zxf sphinx-3.0.2-2592786-linux-amd64.tar.gz && \
    cd sphinx-3.0.2-2592786-linux-amd64/bin && \
    ./searchd
#RUN dpkg -i sphinxsearch_2.2.11-dev-0ubuntu12~trusty_amd64.deb
#RUN add-apt-repository ppa:builds/sphinxsearch-rel22 && apt-get update
RUN apt-get install -y sphinxsearch

#RUN apt-get update && apt-get install build-essential
RUN apt-get update && wget https://www.imagemagick.org/download/ImageMagick.tar.gz
RUN tar xvzf ImageMagick.tar.gz
RUN ls && \
    cd ImageMagick*/ && \
    ./configure && \
    make && \
    sudo make install && \
    ldconfig /usr/local/lib

# sendmail config  https://stackoverflow.com/questions/47247952/send-email-on-testing-docker-container-with-php-and-sendmail/47485123#47485123
############################################

RUN apt-get install -q -y ssmtp mailutils

# root is the person who gets all mail for userids < 1000
RUN echo "root=balagan.astana@gmail.com" >> /etc/ssmtp/ssmtp.conf

# Here is the gmail configuration (or change it to your private smtp server)
RUN echo "mailhub=smtp.gmail.com:587" >> /etc/ssmtp/ssmtp.conf
RUN echo "AuthUser=balagan.astana@gmail.com" >> /etc/ssmtp/ssmtp.conf
RUN echo "AuthPass=*********" >> /etc/ssmtp/ssmtp.conf

RUN echo "UseTLS=YES" >> /etc/ssmtp/ssmtp.conf
RUN echo "UseSTARTTLS=YES" >> /etc/ssmtp/ssmtp.conf
RUN apt-get install memcached
RUN service memcached start
COPY entrypoint.sh /
WORKDIR /home/developer/sharetribe
ENTRYPOINT ["/entrypoint.sh"]
