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

ENV NPM_CONFIG_LOGLEVEL="info" \
    NODE_VERSION="7.8.0" \
    PM_CONFIG_LOGLEVEL="error" \
    NPM_CONFIG_PRODUCTION="true"

RUN set -ex && \
    for key in \
        9554F04D7259F04124DE6B476D5A82AC7E37093B \
        94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
        FD3A5288F042B6850C66B31F09FE44734EB7990E \
        71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
        DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
        B9AE9905FFD7803F25714661B63B535A4C206CA9 \
        C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
        56730D5401028683275BD23C23EFEFE93C4CFFFE \
    ; do \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
        gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
        gpg --keyserver keyserver.pgp.com --recv-keys "$key" ; \
    done

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" && \
    curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" && \
    gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc && \
    grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - && \
    tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 && \
    rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt && \
    ln -s /usr/local/bin/node /usr/local/bin/nodejs
    
RUN npm install

### Installing bundle

RUN mkdir /opt/gem_folder

COPY Gemfile /opt/gem_folder
COPY Gemfile.lock /opt/gem_folder

WORKDIR /opt/gem_folder

RUN gem install bundler:2.0.2 && \
    bundle update delayed_job && \
    gem install foreman && \
    bundle install

#ENV GEM_HOME /home/ticketbuster/gem_folder

#RUN gem install foreman

#WORKDIR /

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
