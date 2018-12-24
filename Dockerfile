FROM test/app:latest

# User config
ENV UID="1000" \
    UNAME="developer" \
    GID="1000" \
    GNAME="developer" \
    SHELL="/bin/bash" \
    UHOME=/home/developer

# Used to configure YouCompleteMe
ENV GOROOT="/usr/lib/go"
ENV GOBIN="$GOROOT/bin"
ENV GOPATH="$UHOME/workspace"
ENV PATH="$PATH:$GOBIN:$GOPATH/bin"

# User
RUN apk --no-cache add sudo \
# Create HOME dir
    && mkdir -p "${UHOME}" \
    && chown "${UID}":"${GID}" "${UHOME}" \
# Create user
    && echo "${UNAME}:x:${UID}:${GID}:${UNAME},,,:${UHOME}:${SHELL}" \
    >> /etc/passwd \
    && echo "${UNAME}::17032:0:99999:7:::" \
    >> /etc/shadow \
# No password sudo
    && echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" \
    > "/etc/sudoers.d/${UNAME}" \
    && chmod 0440 "/etc/sudoers.d/${UNAME}" \
# Create group
    && echo "${GNAME}:x:${GID}:${UNAME}" \
    >> /etc/group

# Install Pathogen
RUN apk --no-cache add curl \
    && mkdir -p \
    $UHOME/bundle \
    $UHOME/.vim/autoload \
    $UHOME/.vim_runtime/temp_dirs \
    && curl -LSso \
    $UHOME/.vim/autoload/pathogen.vim \
    https://tpo.pe/pathogen.vim \
    && echo "execute pathogen#infect('$UHOME/bundle/{}')" \
    > $UHOME/.vimrc \
    && echo "syntax on " \
    >> $UHOME/.vimrc \
    && echo "filetype plugin indent on " \
    >> $UHOME/.vimrc \
# Cleanup
    && apk del curl

# Vim wrapper
COPY run /usr/local/bin/
#custom .vimrc stub
RUN mkdir -p /ext  && echo " " > /ext/.vimrc

COPY .vimrc $UHOME/my.vimrc

# Vim plugins deps
RUN apk --update add \
    bash \
    ctags \
    curl \
    git \
    ncurses-terminfo \
    python3 \
# YouCompleteMe
    && apk add --virtual build-deps \
    build-base \
    cmake \
    go \
    llvm \
    perl \
    python3-dev \
    && git clone --depth 1  https://github.com/Valloric/YouCompleteMe \
    $UHOME/bundle/YouCompleteMe/ \
    && cd $UHOME/bundle/YouCompleteMe \
    && git submodule update --init --recursive \
    && python3 $UHOME/bundle/YouCompleteMe/install.py \
# Install and compile procvim.vim
    && git clone --depth 1 https://github.com/Shougo/vimproc.vim \
    $UHOME/bundle/vimproc.vim \
    && cd $UHOME/bundle/vimproc.vim \
    && make \
    && chown $UID:$GID -R $UHOME \
# Cleanup
    && apk del build-deps \
    && apk add \
    libxt \
    libx11 \
    libstdc++ \
    && rm -rf \
    $UHOME/bundle/YouCompleteMe/third_party/ycmd/clang_includes \
    $UHOME/bundle/YouCompleteMe/third_party/ycmd/cpp \
    /usr/lib/go \
    /var/cache/* \
    /var/log/* \
    /var/tmp/* \
    && mkdir /var/cache/apk

USER $UNAME

# Plugins
#RUN cd $UHOME/bundle/ \
#    && git clone --depth 1 https://github.com/pangloss/vim-javascript \

# Theme
#    && git clone --depth 1 \
#    https://github.com/altercation/vim-colors-solarized

# Build default .vimrc
RUN  mv -f $UHOME/.vimrc $UHOME/.vimrc~ \
     && curl -s \
     https://raw.githubusercontent.com/amix/vimrc/master/vimrcs/basic.vim \
     >> $UHOME/.vimrc~ \
     && curl -s \
     https://raw.githubusercontent.com/amix/vimrc/master/vimrcs/extended.vim \
     >> $UHOME/.vimrc~ \
     && cat  $UHOME/my.vimrc \
     >> $UHOME/.vimrc~ \
     && rm $UHOME/my.vimrc \
     && sed -i '/colorscheme peaksea/d' $UHOME/.vimrc~

# Pathogen help tags generation
RUN vim -E -c 'execute pathogen#helptags()' -c q ; return 0

ENV TERM=xterm-256color

# List of Vim plugins to disable
ENV DISABLE=""

ENTRYPOINT ["sh", "/usr/local/bin/run"]
