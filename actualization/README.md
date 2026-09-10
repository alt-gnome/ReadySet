# Upstream tracking

Some Ready Set components are adapted from upstream projects that may change
independently. The files in [`tracking/`](tracking/) describe the upstream
repositories to watch. [`check.py`](check.py) compares the tracked revisions and
reports changes that need review before they are incorporated into this project.

The tracking data is a maintenance aid: an upstream change must still be
reviewed and integrated through a normal pull request.
