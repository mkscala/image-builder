var aws = require('aws-sdk');
var async = require('async');
var mkdirp = require('mkdirp');

var path = require('path');
var join = path.join;
var uuid = require('uuid');
var os = require('os');
var fs = require('fs');

var options = {};

main();

function main () {
  /* arguments
   * --bucket *
   * --file
   * --files
   * --prefix *
   * --dest *
   */
  var argv = require('minimist')(process.argv.slice(2));

  var bucket = argv.bucket;
  var prefix = argv.prefix;
  var files = argv.files ? JSON.parse(argv.files) : null;
  var file = argv.file;
  var dest = argv.dest;

  if (file && !files) {
    downloadFile(
      bucket,
      file,
      prefix,
      null,
      dest,
      handleResponse);
  } else if (files && !file) {
    downloadFiles(
      bucket,
      files,
      prefix,
      dest,
      handleResponse);
  } else {
    console.error('Need a file to download!');
    process.exit(2);
  }

  function handleResponse (err, res) {
    if (err) {
      console.log(err);
      process.exit(1);
    }
    process.exit(0);
  }
}

function downloadFiles (bucket, files, filePrefix, tempDir, callback) {
  var fileActions = [];
  Object.keys(files).forEach(function (key) {
    fileActions.push(downloadFile.bind(this,
      bucket,
      key,
      filePrefix,
      files[key],
      tempDir
    ));
  });
  async.parallel(fileActions, callback);
}

function downloadFile (bucket, file, prefix, version, dest, callback) {
  aws.config.update({
    accessKeyId: process.env.RUNNABLE_AWS_ACCESS_KEY,
    secretAccessKey: process.env.RUNNABLE_AWS_SECRET_KEY
  });
  var s3 = new aws.S3();

  var data = {
    Bucket: bucket,
    Key: file
  };
  if (version) {
    data.VersionId = version;
  }
  s3.getObject(data, function (err, data) {
    if (err) { return callback(err); }
    file = prefix ? file.slice(prefix.length) : file;
    var fileName = join(dest, file);
    if (fileName.slice(-1) === '/') {
      mkdirp.sync(fileName);
      callback(null, fileName);
    } else {
      mkdirp.sync(path.dirname(fileName));
      fs.writeFile(fileName, data.Body, function (err) {
        if (err) { return callback(err); }
        callback(null, fileName);
      });
    }
  });
}
