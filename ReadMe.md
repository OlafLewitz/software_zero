Basics
======

    bundle install
    cp .env.example .env   # change the secret token in this file to something long and random

Running a rails server
----------------------

    bundle exec foreman run "rails server -p 2222"

Look for your app here: http://localhost:2222/

Running a rails console
-----------------------

    bundle exec foreman run rails console

Crawling Sites
==============

While you can download pages one at a time through the web interface,
you can also crawl entire sites from the command line:

    bundle exec foreman run "bin/zero [url to crawl]"

Note that you may wish to adjust MAX_LINKS_PER_SITE in your .env file.

Heroku Note
===========

If you deploy these apps to heroku, you may find the heroku-config extension useful for pushing config files:

    bundle exec heroku plugins:install git://github.com/ddollar/heroku-config.git
    bundle exec heroku config:push

FedWiki Developers
==================

If you are looking for Smallest Federated Wiki related code, try this branch:
https://github.com/harlantwood/software_zero/tree/fedwiki_backed