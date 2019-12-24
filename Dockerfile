FROM lambci/lambda:build-nodejs12.x

RUN export LC_CTYPE=en_US.UTF-8
RUN export LC_ALL=en_US.UTF-8
# RUN yum-config-manager --enable epel
RUN yum install -y \
    autoconf \
    ccache \
    expat-devel \
    expat-devel.x86_64 \
    fontconfig-devel \
    git \
    gmp-devel \
    google-crosextra-caladea-fonts \
    google-crosextra-carlito-fonts \
    gperf \
    icu \
    libcurl-devel \
    liberation-sans-fonts \
    liberation-serif-fonts \
    libffi-devel \
    libICE-devel \
    libicu-devel \
    libmpc-devel \
    libpng-devel \
    libSM-devel \
    libX11-devel \
    libXext-devel \
    libXrender-devel \
    libxslt-devel \
    mesa-libGL-devel \
    mesa-libGLU-devel \
    mpfr-devel \
    nasm \
    nspr-devel \
    nss-devel \
    openssl-devel \
    perl-Digest-MD5 \
    python34-devel

RUN yum groupinstall -y "Development Tools"

# install liblangtag (not available in Amazon Linux or EPEL repos)
# RUN nano /etc/yum.repos.d/centos.repo

# paste repo info from https://unix.stackexchange.com/questions/433046/how-do-i-enable-centos-repositories-on-rhel-red-hat
RUN yum repolist
RUN yum install -y liblangtag
RUN cp -r /usr/share/liblangtag /usr/local/share/liblangtag/

RUN yum install -y curl
RUN curl -L https://github.com/LibreOffice/core/archive/libreoffice-6.2.1.2.tar.gz | tar -xv

RUN mv core-libreoffice-6.2.1.2 libreoffice
RUN cd libreoffice

# see https://ask.libreoffice.org/en/question/72766/sourcesver-missing-while-compiling-from-source/
RUN echo "lo_sources_ver=6.2.1.2" >> sources.ver

# RUN curl -L http://download-ib01.fedoraproject.org/pub/epel/7/x86_64/

# RUN rpm -Uvh epel-release*rpm


# RUN yum install ccache

# # set this cache if you are going to compile several times
# RUN ccache --max-size 32 G && ccache -s

# See https://git.io/fhAJ0
# RUN yum remove -y gcc48-c++ 
# RUN yum install -y gcc72 gcc72-c++
RUN yum install gcc-c++

# the most important part. Run ./autogen.sh --help to see wha each option means
RUN ./autogen.sh \
    --disable-avahi \
    --disable-cairo-canvas \
    --disable-coinmp \
    --disable-cups \
    --disable-cve-tests \
    --disable-dbus \
    --disable-dconf \
    --disable-dependency-tracking \
    --disable-evolution2 \
    --disable-dbgutil \
    --disable-extension-integration \
    --disable-extension-update \
    --disable-firebird-sdbc \
    --disable-gio \
    --disable-gstreamer-0-10 \
    --disable-gstreamer-1-0 \
    --disable-gtk \
    --disable-gtk3 \
    --disable-introspection \
    --disable-kde4 \
    --disable-largefile \
    --disable-lotuswordpro \
    --disable-lpsolve \
    --disable-odk \
    --disable-ooenv \
    --disable-pch \
    --disable-postgresql-sdbc \
    --disable-python \
    --disable-randr \
    --disable-report-builder \
    --disable-scripting-beanshell \
    --disable-scripting-javascript \
    --disable-sdremote \
    --disable-sdremote-bluetooth \
    --enable-mergelibs \
    --with-galleries="no" \
    --with-system-curl \
    --with-system-expat \
    --with-system-libxml \
    --with-system-nss \
    --with-system-openssl \
    --with-theme="no" \
    --without-export-validation \
    --without-fonts \
    --without-helppack-integration \
    --without-java \
    --without-junit \
    --without-krb5 \
    --without-myspell-dicts \
    --without-system-dicts

# Disable flaky unit test failing on macos (and for some reason on Amazon Linux as well)
RUN nano ./vcl/qa/cppunit/pdfexport/pdfexport.cxx
# find the line "void PdfExportTest::testSofthyphenPos()" (around 600)
# and replace "#if !defined MACOSX && !defined _WIN32" with "#if defined MACOSX && !defined _WIN32"

# this will take 0-2 hours to compile, depends on your machine
RUN make

# this will remove ~100 MB of symbols from shared objects
RUN strip ./instdir/**/*

# remove unneeded stuff for headless mode
RUN rm -rf ./instdir/share/gallery \
    ./instdir/share/config/images_*.zip \
    ./instdir/readmes \
    ./instdir/CREDITS.fodt \
    ./instdir/LICENSE* \
    ./instdir/NOTICE

# archive
RUN tar -cvf lo.tar instdir

# RUN curl -L https://github.com/vladgolubev/serverless-libreoffice/releases/download/ v6.1.0.0.alpha0/lo.tar.gz -o lo.tar.gz
# RUN yum install -y wget gcc make bc sed autoconf automake libtool git tree
# RUN git clone https://github.com/google/brotli.git
# RUN cd brotli
# RUN cp ~/brotli/docs/brotli.1 /usr/share/man/man1 
# RUN gzip /usr/share/man/man1/brotli.1
# RUN ./bootstrap
# RUN ./configure --prefix=/usr  --bindir=/usr/bin --sbindir=/usr/sbin --libexecdir=/usr/lib64/brotli --libdir=/usr/lib64/brotli --datarootdir=/usr/share --mandir=/usr/share/man/man1 --docdir=/usr/share/doc
# RUN make
# RUN make install

# RUN brotli -Z -j lo.tar

RUN pwd
# test if compilation was successful
RUN echo "hello world" > a.txt
RUN ./instdir/program/soffice --headless --invisible --nodefault --nofirststartwizard \
    --nolockcheck --nologo --norestore --convert-to pdf --outdir $(pwd) a.txt

# ADD Gemfile /var/task/Gemfile
# ADD Gemfile.lock /var/task/Gemfile.lock

# RUN bundle install --without development test --deployment