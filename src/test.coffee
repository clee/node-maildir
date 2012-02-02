#!/usr/bin/env coffee

Maildir = require '../lib/maildir'
{testCase} = require 'nodeunit'
fs = require 'fs'

module.exports = {
	setUp: (callback) =>
		fs.mkdir "./test/maildir", ->
			fs.mkdir "./test/maildir/cur", ->
				fs.mkdir "./test/maildir/new", ->
					callback()

	# Teardown doesn't seem to work correctly. TODO: Fix it later.
	###
	tearDown: (callback) =>
		(fs.unlinkSync "./test/maildir/cur/#{file}" for file in fs.readdirSync "./test/maildir/cur")
		console.log "wiped cur"
		(fs.unlinkSync "./test/maildir/new/#{file}" for file in fs.readdirSync "./test/maildir/new")
		console.log "wiped new"
		fs.rmdir "./test/maildir/new", ->
			console.log "removed new"
			fs.rmdir "./test/maildir/cur", ->
				console.log "removed cur"
				fs.rmdir "./test/maildir", ->
					console.log "removed maildir"
					callback()
	###

	"Create empty maildir": (test) ->
		test.expect 1
		maildir = new Maildir "./test/maildir"
		test.ok maildir != null, "The maildir should exist"
		test.done()

	"New message in maildir": (test) ->
		test.expect 2
		maildir = new Maildir "./test/maildir"
		messageListener = (message) ->
			test.equal message.headers.subject, "ABCDEF"
			test.equal message.headers['x-test'], "ÕÄÖÜ"
			maildir.shutdown ->
				test.done()
		maildir.on "newMessage", messageListener
		maildir.monitor()
		sampleText = "Subject: ABCDEF\r\n" + "X-Test: =?UTF-8?Q?=C3=95=C3=84?= =?UTF-8?Q?=C3=96=C3=9C?=\r\n\r\nbody here"
		setTimeout (fs.writeFileSync "./test/maildir/new/#{Date.now()}.hack", sampleText), 1000
}
