FROM perl:slim
RUN apt update
RUN apt install -y \
    ca-certificates \
    libssl1.1 \
    libssl-dev \
    zlib1g-dev \
    libreadline-dev \
    libreadline7 \
    readline-common \
    sqlite3 \
    libsqlite3-0 \
    libsqlite3-dev \
    build-essential

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
    App::Ack \
    Data::Dumper

RUN rm -f /root/.cpan/build.log && rm -f /root/.cpan/latest-build
RUN apt -y purge build-essential
RUN apt -y autoremove
RUN apt clean

RUN mkdir /root/.re.pl
RUN echo "use v5.34;\nuse strictures 2;\nuse Data::Dumper;\nuse experimental qw(signatures switch);\nuse feature 'try';\n" > /root/.re.pl/repl.rc
RUN chown -R root:root /root
WORKDIR /perl
CMD ["tail", "-f", "/dev/null"]
