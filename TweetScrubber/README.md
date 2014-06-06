## README
Simple Tweet Curation App. 
Data is stored in sqlite database on the deployed machine.
Notable Packages Used:
- Openssl for connection level security
- Devise for Users / User Access Control
- Handlebars for templating
- Bootstrap for styling

### Orientation
If you are unfamiliar with RoR applications:
* Object Relational Mapping (ORM) is handled in subclasses of ActiveRecord::Base.
  * In this app, these classes do the heavy lifting in terms of computational tasks
  * Model Classes are in app/model
  * tweeter.rb 	-> wrapper for a twitter user
  * user.rb 		-> a TweetScrubber User
* Handling requests and returning the appropriate response Are handled by controllers
  * app/controllers
  * application_controller -> base class, allows for global configurations
  * index_controller 		-> handles requests to homepage
  * tweeters_controller 	-> handles requests to curation app
  * users_controller 		-> handles user configuration (specifying password and twitter credentials)
* Page templates (Views)
  * app/views
  * mixed ruby and html code page templates
  * grouped by controller
* Client Side Assets (eg javascripts) are in app/assets
  * assets/javascripts/tweeters.js 	-> logic for curation application 
  * assets/javascripts/templates/ 	-> handle bars templates used on various pages
* General Settings are in config/
* DB specific Settings (credentials, connection parameters, schema) are in db/ 

### Setup
Tested and deployed with RoR 4.0 on Ruby 2.1. Uses Thin as the webserver.
App forces SSL on all connections.

