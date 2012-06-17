require_relative 'store'
require_relative '../run_cmd'

class GithubStore < Store
  class << self

    include RunCmd

    ### GET

    def get_text(path)
      path = relative_path(path)

      text
    end

    alias_method :get_blob, :get_text

    ### PUT

    def put_text(path, text, metadata={})
      user = ENV['GITHUB_USER'] || raise("Please set env var GITHUB_USER")
      password = ENV['GITHUB_PASS'] || raise("Please set env var GITHUB_PASS")
      repo = metadata[:subdomain]

      @github = Github.new :basic_auth => "#{user}:#{password}"

      repo! user, repo
      last_commit_sha = @github.git_data.references.get(user, repo, 'heads/master').object.sha
      last_tree_sha = @github.git_data.commits.get(user, repo, last_commit_sha).tree.sha


      # create tree object (also implicitly creates a blob based on content)
      new_content_tree_sha = @github.git_data.trees.create(user, repo,
                                                       :base_tree => last_tree_sha,
                                                       :tree => [
                                                         {
                                                           :path => path,
                                                           :content => text,
                                                           :mode => '100644'
                                                         }
                                                       ]).sha

      new_commit_sha = @github.git_data.commits.create(user, repo,
                                                       :parents => [last_commit_sha],
                                                       :tree => new_content_tree_sha,
                                                       :message => 'commit via api'
      ).sha

      # update branch to point to new commit
      @github.git_data.references.update(user, repo, 'heads/master', :sha => new_commit_sha)

      text
    end

    def repo!(user, repo_name)
      begin
        @github.repos.get(user, repo_name)
      rescue Github::Error::NotFound
        repo = @github.repos.create(:name => repo_name, :has_wiki => true)
        remote = "https://#{ENV['GITHUB_USER']}:#{ENV['GITHUB_PASS']}@github.com/#{ENV['GITHUB_USER']}/#{repo_name}.git"
        run "mkdir -p #{Rails.root.join('zero')}"
        run "cd #{Rails.root.join('zero')} && git clone #{repo.clone_url}"
        run "cd #{Rails.root.join('zero', repo_name)} && git commit --allow-empty -m 'Initial commit'"
        run "cd #{Rails.root.join('zero', repo_name)} && git push #{remote} HEAD"
      end
    end

    def put_blob(path, blob)
      raise NotImplementedError
    end

    ### COLLECTIONS

    def page_metadata(farm_dir, max_pages)
      raise NotImplementedError
    end

    def annotated_pages(pages_dir)
      raise NotImplementedError
    end

    ### UTILITY

    def has_pages?(pages_dir)
      raise NotImplementedError
    end

    def farm?(_)
      ENV['FARM_MODE']
    end

    def mkdir(_)
      # do nothing
    end

    def exists?(path)
      !(get_text path).nil?
    end
  end
end
