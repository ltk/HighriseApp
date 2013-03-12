# Gemfile
require "rubygems"
require "bundler/setup"
require "sinatra"
require "highrise"
require "./app"
 
set :run, false
set :raise_errors, true
 
run HighriseApp