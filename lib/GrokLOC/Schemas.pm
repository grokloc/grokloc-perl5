package GrokLOC::Schemas;
use strictures 2;
use Readonly;

# ABSTRACT: Full schema definitions for GrokLOC dbs.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

Readonly::Scalar our $APP => <<'APP';
-- 1 up
create table if not exists users (
       id text unique not null,
       display text not null,
       display_digest text not null,
       email text unique not null,
       email_digest text unique not null,
       password text not null,
       org text not null,
       api_secret text unique not null,
       api_secret_digest text unique not null,
       version integer not null default 0,
       status integer not null,
       ctime integer,
       mtime integer, 
       primary key (id));

create unique index if not exists email_org on users (email_digest, org);

create trigger if not exists users_ctime_trigger after insert on users
begin
        update users set 
        ctime = strftime('%s','now'), 
        mtime = strftime('%s','now') 
        where id = new.id;
end;

create trigger if not exists users_mtime_trigger after update on users
begin
        update users set mtime = strftime('%s','now') 
        where id = new.id;
end;

create table if not exists orgs (
       id text unique not null,
       name text unique not null,
       owner text not null,
       version integer not null default 0,
       status integer not null,
       ctime integer,
       mtime integer,
       primary key (id));

create trigger if not exists orgs_ctime_trigger after insert on orgs
begin
        update orgs set 
        ctime = strftime('%s','now'), 
        mtime = strftime('%s','now') 
        where id = new.id;
end;

create trigger if not exists orgs_mtime_trigger after update on orgs
begin
        update orgs set mtime = strftime('%s','now') 
        where id = new.id;
end;

create table if not exists repositories (
       id text unique not null,
       name text unique not null,
       org text not null,
       path text not null,
       url text not null,
       version integer not null default 0,
       status integer not null,
       ctime integer,
       mtime integer,
       primary key (id));

create trigger if not exists repositories_ctime_trigger after insert on repositories
begin
        update repositories set 
        ctime = strftime('%s','now'), 
        mtime = strftime('%s','now') 
        where id = new.id;
end;

create trigger if not exists repositories_mtime_trigger after update on repositories
begin
        update repositories set mtime = strftime('%s','now') 
        where id = new.id;
end;
-- 1 up
drop trigger users_mtime_trigger;
drop trigger users_ctime_trigger;
drop table users;
drop trigger orgs_mtime_trigger;
drop trigger orgs_ctime_trigger;
drop table orgs;
drop trigger repositories_mtime_trigger;
drop trigger repositories_ctime_trigger;
drop table repositories;
APP

1;

__END__

=head1 NAME

GrokLOC::Schemas

=head1 SYNOPSIS

Full schema definitions for GrokLOC dbs. 

Intended to be used with the Mojo::* db packages.

=head1 DESCRIPTION

State instance info for the GrokLOC app.

=cut
