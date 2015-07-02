gulp        = require('gulp')
$           = require('gulp-load-plugins')()
argv        = require('minimist')(process.argv.slice(2))
browserSync = require('browser-sync')
runSequence = require('run-sequence')

# グローバルヘッダがロードされるとリダイレクト?されるので
# ヘッダが無いブログを指定する必要あり
blog = 'http://blog.kentarok.org/'
 
# gulp watch --blog=http://www.exapmle.com 
blog = argv.blog if argv.blog

glob =
  dist   : 'dist/**/*'
  images : 'assets/images/**/*'
  sass   : 'assets/styles/**/*.scss'

dist =
  images : 'dist/images'
  sass   : 'dist/styles'

devEnv       = process.env.NODE_ENV || 'development'
devEnv       = 'production' if argv.production
isProduction = true if devEnv == 'production'

gulp.task 'images', ->
  gulp
    .src  glob.images
    .pipe $.changed dist.images
    .pipe $.imagemin
      progressive: true
      interlaced: true
    .pipe gulp.dest dist.images

gulp.task 'sass', ->
  gulp
    .src glob.sass
    .pipe $.if !isProduction, $.sourcemaps.init()
    .pipe $.plumber( {errorHandler: $.notify.onError("Error: <%= error.message %>")} )
    .pipe $.sass
      includePaths: require('node-neat').includePaths
    .pipe $.autoprefixer 'last 1 version', 'ie 9'
    .pipe $.minifyCss()
    .pipe $.if !isProduction, $.sourcemaps.write '.'
    .pipe gulp.dest dist.sass
    .pipe $.if !isProduction, browserSync.stream(match:'**/*.css')

gulp.task 'watch', ['build'], ->
  browserSync
    proxy: blog
    middleware: require('serve-static')('dist')
    rewriteRules: [
      {
        match: /http\:\/\/blog.hatena.ne.jp\/\-\/blog_style\/[^"]+/i
        fn: (match)->
          return '/styles/main.css?'
      }
      #{
      #  match: /<script.*blog.hatena.ne.jp.*script>/i
      #  fn: (match)->
      #    return ''
      #}
    ]

  gulp.watch [glob.sass], ['sass']
  gulp.watch [glob.images], ['images']

gulp.task 'clean', require('del').bind(null, [glob.dist])

gulp.task 'build', (cb) ->
  runSequence 'clean', ['sass', 'images'], cb

gulp.task 'default', ->
  gulp.start 'build'

