# Should be 1 for domains like example.com or lvh.me; 2 for example.co.uk or example.com.au
ActionDispatch::Http::URL.tld_length = ENV['BASE_DOMAIN'].split('.').size - 1