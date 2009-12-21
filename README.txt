= semrush-client

== DESCRIPTION:

Client for the SEMRush API (http://www.semrush.com/api.html)

== SYNOPSIS:

  require 'semrush/client'
  c = SEMRush::Client.new("my_api_key")

  # Organic keywords from domain
  c.organic("example.com", :limit => 10, :offset => 5, :db => "us", 
                           :ip => "127.0.0.1")

  # Related keywords
  c.related("cat dog")

  # URL report
  c.url_report(:url => "http://example.com/")
  
  See API docs for more

== REQUIREMENTS:

* ActiveSupport >= 2.0.2

== LICENSE:

Copyright (c) 2009 Cramer Development, Inc.

All rights reserved.

