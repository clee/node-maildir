import { EventEmitter } from 'node:events';
import * as fs from 'node:fs/promises';

import { simpleParser } from 'mailparser';
import * as chokidar from 'chokidar';

class Maildir extends EventEmitter {
  // Create a new Maildir object given a path to the root of the Maildir
  constructor(maildir) {
    super();
    this.maildir = maildir;
    this.files = new Array();
    this.watchers = {}
  }

  get count() {
    return this.files.length;
  }

  // remove the listeners, kill watcher, end the world
  shutdown() {
    return new Promise(async (resolve) => {
      let ref, key;
      this.removeAllListeners();
      for (key in this.watchers) {
        if ((ref = this.watchers[key]) === null) {
          continue;
        }
        await ref.close();
      }
      resolve();
    });
  }

  // Notify the client about all the new messages that already exist
  async monitor() {
    await this.update_files();
    await this.divine_new_messages();
    // don't overwrite our existing watchers
    if ('cur' in this.watchers && 'new' in this.watchers) {
      return;
    }
    // we *should* get a notification whenever a file appears in `new/`
    let newWatcher = chokidar.watch(`.`, {cwd: `${this.maildir}/new/`, depth: 1});
    newWatcher.on('add', path => this.notify_new_message(path));
    this.watchers['new'] = newWatcher;

    let curWatcher = chokidar.watch(`.`, {cwd: `${this.maildir}/cur/`, depth: 1});
    curWatcher.on('unlink', path => this.notify_deleted_message(path));
    this.watchers['cur'] = curWatcher;
  }
  
  update_files() {
    return new Promise(async (resolve, reject) => {
      try {
        let files = [];
        let dir = await fs.opendir(`${this.maildir}/cur/`);
        for await (const file of dir) {
          files.push(`${this.maildir}/cur/${file.name}`);
        }
        this.files = files;
        resolve(files);
      } catch (err) {
        reject(err);
      }
    });
  }

  // Emit the newMessage event for mail at a given fs path
  async notify_new_message(path) {
    if (path === null || path === undefined) {
      return;
    }
    var file;
    if (typeof path == "Object" && 'name' in path) {
      file = path.name;
    } else {
      file = path;
    }
    const origin = `${this.maildir}/new/${file}`;
    const destination = `${this.maildir}/cur/${file}:2,`;

    console.log(`moving from ${origin} to ${destination}`);
    await fs.rename(origin, destination);
    console.log('emitting newMessage');
    this.emit('newMessage', await this.loadMessage(destination));
  }

  // A message has been deleted! Let's tattle.
  notify_deleted_message(path) {
    console.log(`${path} deleted!`)
    this.files = this.files.filter(value => !path.includes(value));
    this.emit('deleteMessage', path);
    console.log('emitted deleteMessage');
  }

  // What messages are new? Let's tell anyone listening about them.
  async divine_new_messages() {
    const dir = await fs.opendir(`${this.maildir}/new/`);
     
    let promises = [];
    for await (const file of dir) {
      promises.push(this.notify_new_message(file.name));
    }
    await Promise.all(promises);
  }

  // Load a parsed message from the Maildir given a path, with a callback
  async loadMessage(path) {
    const file = await fs.open(path);
    const readStream = file.createReadStream();
    
    const message = await simpleParser(readStream);
    file.close();
    return message;
  }

};

export default Maildir;
