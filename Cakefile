#!/usr/bin/env coffee
#
fs = require 'fs'
util = require 'util'
{exec} = require 'child_process'

task 'test', 'run tests', () ->
  async_testing = require 'async_testing'
  async_testing.run('lib/test/tests.js', [])


task 'build', 'src/ --> lib/', () ->
  # .coffee --> .js
  exec 'coffee -co lib src', (err, stdout, stderr) ->
    if err
      util.print stdout
      util.error stderr
      throw new Error "Error while compiling .coffee to .js"
