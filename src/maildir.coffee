# Copyright (c) 2012 Chris Lee <clee@mg8.org>
# MIT Licensed

{EventEmitter} = require "events"
{MailParser} = require "mailparser"
{Inotify} = require "inotify"
fs = require "fs"
os = require "os"

exports.version = "0.5.0"

class Maildir extends EventEmitter
	# Create a new Maildir object given a path to the root of the Maildir
	constructor: (@maildir) ->
		@files = fs.readdirSync "#{@maildir}/cur"
		Object.defineProperty @, 'count', get: => @files.length
		@inotify = if os.platform() is 'linux' then new Inotify(false) else null

	# remove the listeners, kill inotify, end the world
	shutdown: (callback) ->
		@removeAllListeners()
		@inotify?.close()
		callback?()

	# Notify the client about all the new messages that already exist
	monitor: ->
		@divine_new_messages()

		# thanks for nothing, kqueue.
		if os.platform() is not 'linux'
			setInterval @divine_new_messages(), 5000
			return

		# on Linux, we *should* get a notification whenever a file appears in `new/`
		addOptions =
			path: "#{@maildir}/new/"
			watch_for: Inotify.IN_ONLYDIR | Inotify.IN_CREATE | Inotify.IN_MOVED_TO
			callback: (event) =>
				if (event.mask & Inotify.IN_CREATE) or (event.mask & Inotify.IN_MOVED_TO)
					@notify_new_message event.name
		delOptions =
			path: "#{@maildir}/cur/"
			watch_for: Inotify.IN_ONLYDIR | Inotify.IN_DELETE
			callback: (event) =>
				if event.mask & Inotify.IN_DELETE
					@notify_deleted_message event.name
		@inotify.addWatch addOptions
		@inotify.addWatch delOptions

	# Emit the newMessage event for mail at a given fs path
	notify_new_message: (path) ->
		origin = "#{@maildir}/new/#{path}"
		destination = "#{@maildir}/cur/#{path}:2,"
		fs.rename origin, destination, =>
			@loadMessage "#{path}:2,", (message) => @emit "newMessage", message
			fs.readdir "#{@maildir}/cur", (err, files) =>
				@files = files

	# A message has been deleted! Let's tattle.
	notify_deleted_message: (path) ->
		fs.readdir "#{@maildir}/cur", (err, files) =>
			@files = files
			@emit 'deleteMessage', path

	# What messages are new? Let's tell anyone listening about them.
	divine_new_messages: ->
		fs.readdir "#{@maildir}/new", (err, files) =>
			@notify_new_message file for file in files

	# Load a parsed message from the Maildir given a path, with a callback
	loadMessage: (path, callback) ->
		mailparser = new MailParser()
		mailparser.on "end", (message) =>
			message.path = path
			callback message
		fs.createReadStream("#{@maildir}/cur/#{path}").pipe(mailparser)

module.exports = Maildir
