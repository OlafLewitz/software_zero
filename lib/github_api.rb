module GithubApi
  class << self
    def push(params)
      repo = params[:repo]

      get_or_create_repo repo
      last_commit_sha = get_or_create_branch repo, 'master'

      # create the last commit
      # see http://developer.github.com/v3/git/commits/
      last_commit = git_resource :get, repo, "commits/#{last_commit_sha}"
      last_tree_sha = last_commit['tree']['sha']

      new_commit_sha = create_commit repo, params.merge({
                                     :base_tree => last_tree_sha,
                                     :parents => [last_commit_sha]
                                    })
      # update branch to point to new commit
      # see http://developer.github.com/v3/git/refs/
      git_resource :patch, repo, "refs/heads/master",
             :sha => new_commit_sha
    end

    def get_or_create_branch(repo, name)
      begin
        get_branch repo, name
      rescue RestClient::ResourceNotFound
        create_branch repo, name
      end
    end

    def get_branch(repo, branch)
      # get the head of the master branch
      # see http://developer.github.com/v3/git/refs/
      branch = git_resource :get, repo, "refs/heads/#{branch}"
      last_commit_sha = branch['object']['sha']
      last_commit_sha
    end

    def create_branch(repo, name)
      initial_commit =  create_commit repo, {
        :content => 'Initial commit'
      }

      git_resource :post, repo, :refs,
                   :ref => "refs/heads/#{name}",
                   :sha => initial_commit

      #last_commit_sha = branch['object']['sha']
      #last_commit_sha
    end

    def create_commit(repo, params)
      new_content_tree_sha = create_tree params

      # create commit
      # see http://developer.github.com/v3/git/commits/
      new_commit = git_resource :post, repo, :commits,
                          :parents => [last_commit_sha],
                          :tree => new_content_tree_sha,
                          :message => 'commit via api'
    end

    # create tree object (also implicitly creates a blob based on content)
    # see http://developer.github.com/v3/git/trees/
    def create_tree(params)
      git_resource :post, repo, :trees,
                   :base_tree => params[:base_tree],
                   :tree => [{:path => params[:path], :content => params[:content], :mode => '100644'}]
    end


    def git_resource(method, repo, resource, http_params={})
      path = "/repos/#{ENV['GITHUB_USER']}/#{repo}/git/#{resource}"
      resource_url = "https://#{ENV['GITHUB_USER']}:#{ENV['GITHUB_PASS']}@api.github.com#{path}"

      if http_params.empty?
        JSON.parse RestClient.send(method, resource_url)
      else
        JSON.parse RestClient.send(method, resource_url, http_params.to_json, :content_type => :json, :accept => :json)
      end
    end

    def get_or_create_repo(name)
      begin
        get_repo name
      rescue RestClient::ResourceNotFound
        create_repo name
      end
    end

    def create_repo(name)
      path = '/user/repos'
      resource_url = "https://#{ENV['GITHUB_USER']}:#{ENV['GITHUB_PASS']}@api.github.com#{path}"
      http_params = {:name => name}
      p 111, resource_url, http_params
      JSON.parse RestClient.post(resource_url, http_params.to_json, :content_type => :json, :accept => :json)
    end

    def get_repo(name)
      path = "/repos/#{ENV['GITHUB_USER']}/#{name}"
      resource_url = "https://#{ENV['GITHUB_USER']}:#{ENV['GITHUB_PASS']}@api.github.com#{path}"
      p 222, resource_url
      JSON.parse RestClient.get(resource_url)
    end

  end
end
