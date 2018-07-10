# sequel-inline_schema

home
: http://bitbucket.org/ged/sequel-inlineschema

github
: https://github.com/ged/sequel-inlineschema

docs
: http://deveiate.org/code/sequel-inline_schema


## Description

This is a set of plugins for Sequel for declaring a model's table schema and
any migrations in the class itself (similar to the legacy `schema` plugin).

It has only really been tested with PostgreSQL, but patches that make it more generic are welcomed.

The two plugins are:

* Sequel::Plugins::InlineSchema
* Sequel::Plugins::InlineMigrations

Examples and usage documentation are included there.


## Prerequisites

* Ruby >= 2.4
* Sequel >= 5.0


## Installation

    $ gem install sequel-inline_schema


## Contributing

You can check out the current development source with Mercurial via its
[project page][bitbucket]. Or if you prefer Git, via [its Github
mirror][github].

After checking out the source, run:

    $ rake newb

This task will install any missing dependencies, run the tests/specs,
and generate the API documentation.


## License

This plugin uses code from the Sequel project under the MIT License:

Copyright (c) 2007-2008 Sharon Rosner
Copyright (c) 2008-2017 Jeremy Evans

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
  
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
   
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

The rest is licensed under the same terms, but:

Copyright (c) 2017-2018, Michael Granger



[bitbucket]: http://bitbucket.org/ged/sequel-inlineschema
[github]: https://github.com/ged/sequel-inlineschema

