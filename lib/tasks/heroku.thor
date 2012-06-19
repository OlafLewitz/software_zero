require File.dirname(__FILE__) + "/../run_cmd"

class Heroku < Thor
  include RunCmd

  desc "create HEROKU_APP_NAME", 'create a new heroku app'
  def create(app_name)
    run "bundle exec heroku create #{app_name} --stack cedar",
  end

  desc "deploy HEROKU_APP_NAME", "deploy HEAD of current branch to the specified heroku app"
  def deploy(app_name)
    # add remote in case this dev box doesn't have it yet, makes it easier to track
    git_remote = "heroku-#{app_name}"
    unless `git remote`.match( /\b#{git_remote}\b/ )
      run "git remote add #{git_remote} git@heroku.com:#{app_name}.git"
    end

    # deploy: always *to* heroku "master" branch
    run "git push --force #{git_remote} HEAD:master"
    run "heroku restart --app #{app_name}"
  end

end
