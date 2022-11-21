import Maildir from './maildir.mjs';

import * as fs from 'node:fs/promises';

let _maildir;

beforeAll(async () => {
  let paths = ["./test/maildir/cur", "./test/maildir/new"]
  await Promise.all(paths.map((path) => {
    return fs.mkdir(path, {recursive: true});
  }));
  _maildir = new Maildir("./test/maildir");
});

afterAll(async () => {
  await _maildir.shutdown();
});

test("New message in maildir", done => {
  // const sampleText = "Subject: ABCDEF\r\nX-Test: =?UTF-8?Q?=C3=95=C3=84?= =?UTF-8?Q?=C3=96=C3=9C?=\r\n\r\nbody here";

	const sampleText = "Subject: ABCDEF\r\n" + "X-Test: ÕÄÖÜ\r\n\r\nbody here"
  const maildir = _maildir;
  expect.assertions(2);
  maildir.on("newMessage", (message) => {
    expect(message.headers.get('subject')).toBe("ABCDEF");
    expect(message.headers.get('x-test')).toBe("ÕÄÖÜ");
    done();
  });
  maildir.monitor().then(() => {
    fs.writeFile(`${maildir.maildir}/new/${Date.now()}.hack`, sampleText);
  });
});

test("Load message 0", async () => {
  const maildir = _maildir;
  expect.assertions(2);
  await maildir.update_files()
  expect(maildir.count > 0).toBe(true);
  if (maildir.count < 1) {
    return;
  }

  const m = await maildir.loadMessage(maildir.files[0]);
  expect(m != null).toBe(true);
});

test("Delete messsage 0", done => {
  const maildir = _maildir;
  expect.assertions(1);
  maildir.update_files().then(() => {
    const pathToDelete = maildir.files[0];

    maildir.on("deleteMessage", function(pathDeleted) {
      expect(pathToDelete).toContain(pathDeleted);
      done();
    });
    maildir.monitor().then(() => {
      fs.unlink(pathToDelete).then();
    });
  });
});
