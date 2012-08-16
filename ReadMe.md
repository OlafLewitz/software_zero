Intro
=====

Software Zero is intended to bring the fork/diff/merge information topologies,
ubiquitous in open source software development,
to collaborations of all kinds.

More on the full vision of this project on the
[enlightened structure site](http://enlightenedstructure.org/Software_Zero/).

Forking External Web Pages from the Web Interface
=================================================

When pages are forked through the web interface, the user enters a username and topic name.

If in the same SZ instance as described above,
the user enters 'roybaty1' as their username,
and 'singularity' as the topic name, and forks the same page:

    http://en.wikipedia.org/wiki/Technological_singularity

The resulting fork will be at

    http://en-wikipedia-org.via.remixit.cc/wiki-Technological_singularity

And the Github repository will be at

    https://github.com/remixit/en-wikipedia-org

Crawling Sites - Forking External Web Pages via the Command Line
================================================================

While you can download pages one at a time through the web interface,
you can also crawl entire sites from the command line:

    bundle exec foreman run "bin/zero [url to crawl]"

Note that you may wish to adjust MAX_LINKS_PER_SITE in your .env file.

Users can fork any creative commons licenced web page.
The HTML is converted to markdown, and stored in a github repository.
Each instance of Software Zero is associated (via environment variables) with a Github user.
Let us posit a SZ instance running at remixit.cc, with an associated Github user 'remixit'.
If a single page is forked from

    http://en.wikipedia.org/wiki/Technological_singularity

The resulting fork will be at

    http://en-wikipedia-org.on.remixit.cc/wiki-Technological_singularity

And the Github repository will be at

    https://github.com/remixit/en-wikipedia-org

Developing Locally
==================

    bundle install
    cp .env.example .env

Change the secret token in this file to something long and random.
Edit the other environment variables as appropriate.

Running a rails server
----------------------

    bundle exec foreman run "rails server"

Look for your app here: http://localhost:3000/

Running a rails console
-----------------------

    bundle exec foreman run "rails console"

Heroku Note
===========

If you deploy these apps to heroku, you may find the heroku-config extension useful for pushing config files:

    bundle exec heroku plugins:install git://github.com/ddollar/heroku-config.git
    bundle exec heroku config:push

For FedWiki Developers:
=======================

If you are looking for Smallest Federated Wiki related code, look on this branch:
https://github.com/harlantwood/software_zero/tree/fedwiki_backed

Of particular interest is this file, which writes to SFW instances via the HTTP API:
https://github.com/harlantwood/software_zero/blob/fedwiki_backed/lib/fedwiki/fork.rb
