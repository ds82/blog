'use strict';

var metalsmith  = require('metalsmith');
var layout      = require('metalsmith-layouts');
var markdown    = require('metalsmith-markdown');
var less        = require('metalsmith-less');
var mspath      = require('metalsmith-paths');
var collections = require('metalsmith-collections');
var branch      = require('metalsmith-branch');
var permalinks  = require('metalsmith-permalinks');
var excerpts    = require('metalsmith-excerpts');
var browserSync = require('metalsmith-browser-sync');
var assets      = require('metalsmith-assets');
var moment      = require('moment');

var smith = metalsmith(__dirname);

smith
  .metadata({
    site: {
      title: 'blog.dennis.io',
      url: 'http://blog.dennis.io',
      root: '/',
      dateFormat: 'DD.MM.YYYY'
    }
  })
  .source('./source')
  .destination('./public')
  .use(mspath)
  .use(less({
    pattern: '**/*.less',
    render: {
      paths: [
        smith.path('themes/ewal/less')
      ]
    }
  }))
  .use(markdown())
  .use(excerpts())
  .use(function (files, metalsmith, done) {
    var metadata = metalsmith.metadata();
    delete metadata.posts;
    done();
  })
  .use(collections({
    posts: {
      pattern: 'posts/**.html',
      sortBy:  'date',
      reverse: true
    }
  }))
  .use(branch('posts/**.html')
    .use(permalinks({
      pattern: 'posts/:title',
      relative: false
    }))
  )
  .use(branch('!posts/**.html')
    .use(branch('!index.md').use(permalinks({
      relative: false
    })))
  )
  .use(layout({
    engine: 'jade',
    moment: moment,
    directory: './themes/ewal/layouts'
  }))
  .use(assets({
    'source': './themes/ewal/public',
    'destination': 'theme'
  }))
;

if (process.env.WATCH) {
smith.use(
  browserSync({
    server : 'public',
    files  : ['build.js', 'source/**/*.md', 'themes/**/*.jade', 'themes/**/*.less']
  })
);
}

smith.build(function(err) {
  console.log(err || 'done');
});
