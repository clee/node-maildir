#!/usr/bin/env coffee

fs = require 'fs'
util = require 'util'
{exec} = require 'child_process'

task 'test', 'run tests', () ->
	{reporters} = require 'nodeunit'
	reporters.default.run ['lib/test.js']

task 'docs', 'generate docs', () ->
	exec 'docco src/*coffee', (err, stdout, stderr) ->
		if err
			util.print stdout
			util.error stderr
			throw new Error "Error while compiling .coffee to .js"

task 'build', 'src/ --> lib/', () ->
	# .coffee --> .js
	exec 'coffee -co lib src', (err, stdout, stderr) ->
		if err
			util.print stdout
			util.error stderr
			throw new Error "Error while compiling .coffee to .js"
