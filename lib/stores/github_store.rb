require 'github_api'
require_relative 'store'
require_relative '../run_cmd'
require_relative '../core-ext/nil'

class GithubStore < Store
  class << self

    include RunCmd

    ### GET

    def get_text(path, metadata)
      repo = repo_for_reading(metadata)
      begin
        puts "Getting content from #{raw_url(repo, path)} ..."
        RestClient.get raw_url(repo, path)
      rescue RestClient::ResourceNotFound
        nil
      end
    end

    alias_method :get_blob, :get_text

    ### PUT

    def put_text(path, text, metadata)
      raise(ArgumentError, "Expected argument 'path'") unless path
      raise(ArgumentError, "Expected argument 'text'") unless text
      user = ENV['GITHUB_USER'] || raise("Please set env var GITHUB_USER")
      password = ENV['GITHUB_PASS'] || raise("Please set env var GITHUB_PASS")
      repo_name = repo_for_writing(metadata)
      puts "Putting content to:"
      puts "https://github.com/#{ENV['GITHUB_USER']}/#{repo_name}/blob/master/#{path}"

      @github = Github.new :basic_auth => "#{user}:#{password}"

      repo!(user, repo_name)
      last_commit_sha = reference!(user, repo_name, 'heads/master').object.sha
      last_tree_sha = @github.git_data.commits.get(user, repo_name, last_commit_sha).tree.sha


      # create tree object (also implicitly creates a blob based on content)
      begin
        new_content_tree_sha = @github.git_data.trees.create(user, repo_name,
                                                       :base_tree => last_tree_sha,
                                                       :tree => [
                                                         {
                                                           :path => path,
                                                           :content => text,
                                                           :mode => '100644'
                                                         }
                                                       ]).sha
      rescue Faraday::Error::TimeoutError => exception
        STDERR.puts "******************"
        STDERR.puts "We got a Faraday::Error::TimeoutError"
        STDERR.puts "user:          #{user}"
        STDERR.puts "repo:          #{repo_name}"
        STDERR.puts "last_tree_sha: #{last_tree_sha}"
        STDERR.puts "path:          #{path}"
        STDERR.puts "text:"
        STDERR.puts text
        STDERR.puts "******************"
        raise exception
      end

      new_commit_sha = @github.git_data.commits.create(user, repo_name,
                                                       :parents => [last_commit_sha],
                                                       :tree => new_content_tree_sha,
                                                       :message => "Update #{path}"
      ).sha

      # update branch to point to new commit
      @github.git_data.references.update(user, repo_name, 'heads/master', :sha => new_commit_sha)

      text
    end

    def repo!(user, repo_name)
      begin
        @github.repos.get(user, repo_name)
      rescue Github::Error::NotFound
        repo = @github.repos.create(:name => repo_name,
                                    #:homepage => 'xxxxxxx',
                                    :private => false,
                                    :has_issues => false,
                                    :has_wiki => false,
                                    :has_downloads => false,
                                    :has_wiki => false
        )

        # The Github API v3 does not currently support creating an initial commit(!)
        # So we create one manually here via the command line, and push it.
        # Requires git to be in your path.
        remote = "https://#{ENV['GITHUB_USER']}:#{ENV['GITHUB_PASS']}@github.com/#{ENV['GITHUB_USER']}/#{repo_name}.git"

        local_repos_dir = File.join @app_root, 'zero'
        local_repo_dir = File.join local_repos_dir, repo_name
        author_name = ENV['GITHUB_USER']
        author_email = "#{ENV['GITHUB_USER']}@(none)"
        author_env_vars = "GIT_COMMITER_NAME='#{author_name}' GIT_COMMITTER_EMAIL='#{author_email}'"
        author = "#{author_name} <#{author_email}>"

        run "mkdir -p #{local_repos_dir}"
        run "rm -rf #{local_repo_dir}"
        run "cd #{local_repos_dir} && git clone https://github.com/#{ENV['GITHUB_USER']}/#{repo_name}.git"
        run "cd #{local_repo_dir} && #{author_env_vars} git commit --allow-empty --author='#{author}' -m 'Initial commit'"
        run "cd #{local_repo_dir} && git push --quiet #{remote} HEAD"
        repo
      end
    end

    def reference!(user, repo_name, ref_name)
      begin
        @github.git_data.references.get(user, repo_name, ref_name)
      rescue Github::Error::ServiceError
        remote = "https://#{ENV['GITHUB_USER']}:#{ENV['GITHUB_PASS']}@github.com/#{ENV['GITHUB_USER']}/#{repo_name}.git"
        local_repos_dir = File.join @app_root, 'zero'
        local_repo_dir = File.join local_repos_dir, repo_name

        run "mkdir -p #{local_repos_dir}"
        run "rm -rf #{local_repo_dir}"
        run "cd #{local_repos_dir} && git clone https://github.com/#{ENV['GITHUB_USER']}/#{repo_name}.git"
        run "cd #{local_repo_dir} && git commit --allow-empty -m 'Initial commit'"
        run "cd #{local_repo_dir} && git push --quiet #{remote} HEAD"

        @github.git_data.references.get(user, repo_name, ref_name)
      end
    end

    ### UTIL

    def raw_url(repo, path)
      "https://raw.github.com/#{Env['GITHUB_USER']}/#{repo}/master/#{path}"
    end

    private

    def repo_for_reading(metadata)
      extract_repo metadata
    end

    def repo_for_writing(metadata)
      extract_repo metadata
    end

    def extract_repo(metadata)
      keys = [:repo, :collection]
      keys.each{ |key| return metadata[key] unless metadata[key].empty? }
      raise("Please pass in #{keys.map{|key| "metadata[:#{key}]"}.join(' or ')}")
    end

  end
end
