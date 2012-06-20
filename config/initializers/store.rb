require            File.expand_path("../../lib/stores/all",          File.dirname(__FILE__))
require_dependency File.expand_path("../../lib/stores/github_store", File.dirname(__FILE__))

Store.set 'GithubStore', Rails.root

