# Copyright (c) 2012 Chris Lee <clee@mg8.org>
# MIT Licensed

{EventEmitter} = require "events"
{MailParser} = require "mailparser"
fs = require "fs"
_ = require "underscore"

exports.version = "0.0.1"

class Maildir extends EventEmitter
	# Create a new Maildir object given a path to the root of the Maildir
	constructor: (@maildir) ->
		fs.readdir "#{@maildir}/cur", (err, files) =>
			@files = files
			Object.defineProperty @, 'count', get: => @files.length

	# Kill the watcher, remove the listeners, end the world
	shutdown: (callback) ->
		@watcher?.close()
		@removeAllListeners()
		callback?()

	# Notify the client about all the new messages that already exist
	monitor: ->
		@divine_new_messages()

		# ... and set up a watcher on the filesystem so we can provide
		# notifications for all further new messages from here on out
		@watcher = fs.watch "#{@maildir}/new/", (event, path) =>
			# on Linux, we *should* get a path with the name of the new file
			if path?
				@notify_new_message(path)
			# everywhere else sucks. thanks for nothing, kqueue.
			else
				@divine_new_messages()

	# emit the newMessage event for mail at a given fs path
	notify_new_message: (path) ->
		origin = "#{@maildir}/new/#{path}"
		destination = "#{@maildir}/cur/#{path}:2,"
		fs.rename origin, destination, =>
			fs.readdir "#{@maildir}/cur", (err, files) =>
				@files = files
				@loadMessage @count-1, (message) => @emit "newMessage", message

	# what messages are new? let's tell anyone listening about them.
	divine_new_messages: ->
		fs.readdir "#{@maildir}/new", (err, files) =>
			@notify_new_message(file) for file in files

	# Load a parsed message from the Maildir given an index, with a callback
	loadMessage: (index, callback) ->
		mailparser = new MailParser()
		mailparser.on "end", (message) =>
			callback message
		fs.createReadStream("#{@maildir}/cur/#{@files[index]}").pipe(mailparser)

module.exports = Maildir
