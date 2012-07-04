# Be sure to restart your server when you modify this file.

OpenYourProject::Application.config.session_store :cookie_store,
                                                  key: '_software_zero_session',
                                                  :expire_after => 3.hours,
                                                  :domain => ".#{Env['BASE_DOMAIN']}"  # cookies should work for all subdomains as well as base domain

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# OpenYourProject::Application.config.session_store :active_record_store
