# Release History for sequel-inline_schema

---
## v0.3.5 [2025-07-31] Michael Granger <ged@faeriemud.org>

Bugfixes:

- Update for Sequel >= 5.89's labeling of anonymous classes.
  Thanks to mahlon@martini.nu for the patch.


## v0.3.4 [2021-11-08] Michael Granger <ged@faeriemud.org>

Improvements:

- Update for Ruby 3, update gem-signing cert.


## v0.3.3 [2020-02-24] Michael Granger <ged@faeriemud.org>

Bugfixes:

- Allow options to be passed through #drop_table
- Fix view_exists? query for schema-qualified table names


## v0.3.2 [2020-02-11] Michael Granger <ged@faeriemud.org>

Bugfixes:

- Fixed view hooks and added specs.


## v0.3.1 [2020-02-11] Michael Granger <ged@faeriemud.org>

Bugfixes:

- Change back to using `create_view`


## v0.3.0 [2020-02-10] Michael Granger <ged@faeriemud.org>

Improvements:

- Add inline view declaration


## v0.2.0 [2020-01-18] Michael Granger <ged@faeriemud.org>

Improvements:

- Fail on finding migrations with the same `name`. Thanks to
  Alyssa Verkade <averkade@costar.com> for the patch.


## v0.0.1 [2018-07-19] Michael Granger <ged@FaerieMUD.org>

Initial release.

