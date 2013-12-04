# ghissues2bitbucket

[![Gemnasium](https://gemnasium.com/juno/ghissues2bitbucket.png)](https://gemnasium.com/juno/ghissues2bitbucket/)

Import GitHub issues and comments as BitBucket Issues.

**CAUTION: This script is experimental. Be careful when you use this.**

## What's this?

* Read GitHub issues, comments and milestones from JSON
* Create milestones on BitBucket if not exists (Idempotent)
* Force create new issues on BitBucket (Beware, not idempotent)
* Force create new comments on BitBucket (Beware, not idempotent)

## Limitations

* Treat all pull requests on GitHub as BitBucket issues
* All imported issues on BitBucket is reported by a user who authenticated by API call
   * Insert `Originally reported by foo` line to content
* All imported comments on BitBucket is posted by a user who authenticated by API call
   * Insert `Originally commented by foo` line to content

## Prerequisite

* Ruby 1.9 or Ruby 2.0

## Preliminary

ghissues2bitbucket needs `db-1.0.json` file as source.
You can generate `db-1.0.json` by [github-to-bitbucket-issues-migration](https://github.com/sorich87/github-to-bitbucket-issues-migration) script.

    $ git clone git://github.com/sorich87/github-to-bitbucket-issues-migration.git
    $ cd github-to-bitbucket-issues-migration
    $ bundle

If you want to expert GitHub issues from `github/some-repo`, run this:

    $ bundle exec ruby cli.rb github/some-repo USERNAME PASSWORD issues.zip

USERNAME and PASSWORD is for GitHub.

Then, unzip archive to get `db-1.0.json` file.

    $ unzip issues.zip

## Usage

    $ bundle
    $ bundle exec ruby ghissues2bitbucket.rb \
      /path/to/db-1.0.json \
      BIT_BUCKET_USERNAME \
      BIT_BUCKET_PASSWORD \
      REPO_USERNAME \
      REPO_SLUG

`BIT_BUCKET_USERNAME` and `BIT_BUCKET_PASSWORD` is for BitBucket API authentication.

`REPO_USERNAME` and `REPO_SLUG` is for destination repository.
If you want to import issues to BitBucket `foo/some-repo` repository, specify `foo` and `some-repo`.

## Sample output

    Number of issues: 265
    Milestone ver.1.0.5 created
    Milestone ver.1.1.0 created
    Milestone ver.1.0.4 created
    Milestone ver.1.0.2 created
    Issue About response body of API created
    Issue Implement API v1 created
      Comment created
      Comment created
    ...

## How to delete issue

You can delete issues programmatically.

    $ bundle exec irb -rfaraday
    conn = Faraday.new(url: 'https://api.bitbucket.org') do |f|
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end
    conn.basic_auth(BIT_BUCKET_USERNAME, BIT_BUCKET_PASSWORD)
    
    repo_username = 'foo'
    repo_slug = 'bar'
    issue_id = 1
    conn.delete "/1.0/repositories/#{repo_username}/#{repo_slug}/issues/#{issue_id}"

## License

MIT License.
