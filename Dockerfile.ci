FROM debian:bullseye-slim
RUN apt update
RUN apt install -y perlbrew
RUN perlbrew init
RUN perlbrew install perl-5.34.0
RUN perlbrew switch perl-5.34.0
ENV PATH="/root/perl5/perlbrew/perls/perl-5.34.0/bin:${PATH}"

ENV PERL_MM_USE_DEFAULT=1
RUN cpan install App::cpanminus
RUN apt install -y \
    ca-certificates \
    libssl1.1 \
    libssl-dev \
    zlib1g-dev \
    libreadline-dev \
    libreadline8 \
    readline-common \
    sqlite3 \
    libsqlite3-0 \
    libsqlite3-dev

RUN cpanm -n \
    Term::ReadLine::Gnu \
    Mojolicious \
    Test2::Suite \
    Test2::Harness \
    Object::Pad \
    Perl::Tidy \
    Perl::Critic \
    Perl::Critic::TooMuchCode \
    Perl::Tidy::Sweetened \
    List::AllUtils \
    multidimensional \
    indirect \
    bareword::filehandles \
    DBI \
    Devel::REPL \
    Crypt::Argon2 \
    DBD::SQLite \
    Mojo::SQLite \
    Cpanel::JSON::XS \
    CryptX \
    Crypt::JWT \
    EV \
    IO::Socket::Socks \
    IO::Socket::SSL \
    strictures \
    && rm -rf /root/.cpanm/work

RUN rm -f /root/.cpan/build.log && rm -f /root/.cpan/latest-build
RUN apt-get -y purge build-essential
RUN apt-get -y autoremove
RUN apt-get clean

RUN mkdir /root/.re.pl
RUN echo "use v5.34;\nuse strictures 2;\nuse Data::Dumper;\nuse experimental qw(signatures switch);\nuse feature 'try';\n" > /root/.re.pl/repl.rc
RUN chown -R root:root /root
WORKDIR /perl

CMD ["tail", "-f", "/dev/null"]
