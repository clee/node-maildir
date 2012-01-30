#!/usr/bin/env coffee

Maildir = require '../lib/node-maildir'
{testCase} = require 'nodeunit'
fs = require 'fs'

exports["Basic functionality"] = {
	setUp: (callback) ->
		fs.mkdir "./test/maildir", ->
			fs.mkdir "./test/maildir/cur", ->
				fs.mkdir "./test/maildir/new", ->
					callback()

	tearDown: (callback) ->
		(fs.unlinkSync "./test/maildir/cur/#{file}" for file in fs.readdirSync "./test/maildir/cur")
		(fs.unlinkSync "./test/maildir/new/#{file}" for file in fs.readdirSync "./test/maildir/new")
		fs.rmdir "./test/maildir/new", ->
			fs.rmdir "./test/maildir/cur", ->
				fs.rmdir "./test/maildir", ->
					callback()

	"Create empty maildir": (test) ->
		test.expect 1
		maildir = new Maildir "./test/maildir"
		test.ok maildir, "The maildir should exist"
		test.done()

	"New message in maildir": (test) ->
		test.expect 2
		maildir = new Maildir "./test/maildir"
		maildir.on "newMessage", (headers) ->
			test.equal headers.subject, "ABCDEF"
			test.equal headers['x-test'], "ÕÄÖÜ"
			test.done()
		sampleText = "Subject: ABCDEF\r\n" + "X-Test: =?UTF-8?Q?=C3=95=C3=84?= =?UTF-8?Q?=C3=96=C3=9C?=\r\n"
		fs.writeFileSync "./test/maildir/new/#{Date.now()}.hack", sampleText
}
