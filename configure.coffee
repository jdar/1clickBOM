#!/usr/bin/env coffee
fs      = require('fs')
globule = require('globule')
path    = require('path')
cp      = require('child_process')


browserify = 'browserify --debug --extension=".coffee" --transform coffeeify'
#browserifyList = (entry) ->
#    cp.execSync("#{browserify} --list #{entry}").toString().split('\n')
#        .map (f) ->
#            path.relative('./', f)

ninjaBuildGen = require('ninja-build-gen')

ninja = ninjaBuildGen('1.5.1', 'build/')

ninja.header("#generated from #{path.basename(module.filename)}")

ninja.rule('copy').run('cp $in $out')
    .description('$command')

ninja.rule('browserify')
    .run("echo -n '$out: ' > $out.d && #{browserify} $in --list
        | tr '\\n' ' ' >> $out.d && #{browserify} $in -o $out && cat $out.d")
    .depfile('$out.d')

chrome_main_coffee = 'build/.temp-chrome/main.coffee'
chrome_main_js = 'build/chrome/js/main.js'

ninja.edge(chrome_main_js).from(chrome_main_coffee)
    .after(globule.find([
        "src/chrome/coffee/*.coffee"
        "src/common/coffee/*.coffee"
        "src/common/libs/*.js"
        "src/chrome/libs/*.js"
    ]).map (f) ->
        f.replace(/src\/.*?\/.*?\//, "build/.temp-chrome/")
    ).using('browserify')

for browser in ['chrome', 'firefox']
    for f in globule.find([
        "src/#{browser}/coffee/*.coffee"
        "src/common/coffee/*.coffee"
        "src/#{browser}/libs/*.js"
        "src/common/libs/*.js"
    ])
        ninja.edge(f.replace(/src\/.*?\/.*?\//, "build/.temp-#{browser}/"))
            .from(f).using('copy')

ninja.byDefault('build/chrome/js/main.js')
#ninja.edge('chrome')

ninja.save('build.ninja')

console.log('generated build.ninja')
