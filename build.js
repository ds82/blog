'use strict';

var metalsmith = require('metalsmith');
var layout     = require('metalsmith-layouts');
var markdown   = require('metalsmith-markdown');
var less       = require('metalsmith-less');
var moment     = require('moment');

var smith = metalsmith(__dirname);

smith
  .metadata({
    site: {
      title: 'blog.dennis.io',
      url: 'http://blog.dennis.io'
    }
  })
  .source('./source')
  .destination('./public')
  .source('./themes/ewal/less')
  .use(less({
    pattern: '**/*.less',
    render: {
      paths: [
        'themes/ewal/less'
      ]
    }
  }))
  .use(markdown())
  .use(layout({
    engine: 'jade',
    moment: moment,
    directory: './themes/ewal/layouts'
  }))
  .build(function(err) {
    console.log(err || 'done');
  });
