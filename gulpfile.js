var gulp = require('gulp');
var coffee = require('gulp-coffee');
var gutil = require('gulp-util');
var haml = require('gulp-haml');
var express = require('express');
var watch = require('gulp-watch');
var livereload = require('gulp-livereload');

gulp.task('coffee', function() {
  gulp.src('./src/*.coffee')
  .pipe(coffee({bare: true}).on('error', gutil.log))
  .pipe(gulp.dest('./public/'))
});

gulp.task('haml', function () {
  gulp.src('./examples/**/*.haml')
  .pipe(haml())
  .pipe(gulp.dest('./public/'));
});

gulp.task('server', ['coffee', 'haml', 'watch'], function () {
  var app = express();
  var port = 9001;
  var server = app.listen(port);
  app.use(express.static(__dirname));
});

gulp.task('watch', ['haml', 'coffee'], function() {
  var server = livereload();
  server.changed();
  gulp.watch(['./src/**/*.coffee', './example/*'],
             ['coffee', 'haml']).on('change', function(file) {
    server.changed(file.path);
  });
});
