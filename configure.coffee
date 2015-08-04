#!/usr/bin/env coffee
fs      = require('fs')
globule = require('globule')
path    = require('path')
cp      = require('child_process')


browserify = 'browserify --debug --extension=".coffee" --transform coffeeify'
browserifyList = (entry) ->
    cp.execSync("#{browserify} --list #{entry}").toString().split('\n')

ninjaBuildGen = require('ninja-build-gen')

ninja = ninjaBuildGen('1.5.1', 'build/')

ninja.header("#generated from #{path.basename(module.filename)}")

ninja.rule('copy').run('cp $in $out')
    .description('$command')

ninja.rule('browserify')
    .run("#{browserify} $in -o $out")

chrome_main = 'build/.temp-chrome/main.coffee'
ninja.edge('build/chrome/js/main.js').from(chrome_main)
    .need(browserifyList(chrome_main))
    .using('browserify')
#
#ninja.edge('chrome')

ninja.save('build.ninja')

console.log('generated build.ninja')
