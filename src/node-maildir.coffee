# node-maildir
# Copyright(c) 2012 Chris Lee <clee@mg8.org>
# MIT Licensed

{EventEmitter} = require "events"
{MailParser} = require "mailparser"
fs = require "fs"

exports.version = "0.0.1"

class Maildir extends EventEmitter
	# Create a new Maildir object given a path to the root of the Maildir
	constructor: (@maildir) ->
		fs.readdir "#{@maildir}/cur", (err, files) =>
			@count = files.length

		# TODO: Figure out a good cross-platform way to do this. 
		# fs.watch only provides path names on Linux and Windows
		fs.watch "#{@maildir}/new", (event, path) =>
			if event is not "change" or not path?
				console.log "bullshit detected: #{event}: #{path}"
				return

			# We're an MTA now, I guess?
			origin = "#{@maildir}/new/#{path}"
			destination = "#{@maildir}/cur/#{path}:2,"
			fs.rename origin, destination, =>
				@count++
				mailparser = new MailParser()
				mailparser.on "end", (message) =>
					emit "newMessage", {headers: message.headers}
				fs.createReadStream(destination).pipe(mailparser)

	# Load a parsed message from the Maildir given an index, with a callback
	loadMessage: (index, callback) =>
		fs.readdir "#{@maildir}/cur", (err, files) =>
			mailparser = new MailParser()
			mailparser.on "end", (message) =>
				callback {message: message}
			fs.createReadStream(files[index]).pipe(mailparser)

module.exports = Maildir
