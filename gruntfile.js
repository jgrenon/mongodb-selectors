module.exports = function(grunt) {

    require('load-grunt-tasks')(grunt);

    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        coffeelint: {
            options:{
                max_line_length: {
                    level: "ignore"
                }
            },
            app: ['src/**/*.coffee']
        },
        coffee: {
            options:{
                bare:true
            },
            all:{
                expand: true,
                cwd: './src',
                src: ['**/*.coffee'],
                dest: './build',
                ext: '.js'
            }
        },
        copy:{
            peg:{
                expand: true,
                cwd: './src',
                src: 'selector-parser.hbs',
                dest: './build/'
            },
            release:{
                files:[
                    {src: 'package.json', dest: './build/'},
                    {src: 'README.md', dest: './build/'}
                ]
            }
        },
        jasmine_node: {
            options: {
                forceExit: true,
                coffee: true,
                verbose: true,
                match: '.',
                matchall: false,
                extensions: 'coffee',
                specNameMatcher: '-spec'
            },
            env: {
                NODE_ENV: "test"
            },
            unit: ['test/']
        },
        uglify: {
            options: {
                banner: [
                    '/*! ',
                    ' <%= pkg.name %> - v<%= pkg.version %> - <%= grunt.template.today("yyyy-mm-dd") %>',
                    '',
                    '*/',
                    ''
                ].join('\n'),
                compress: {
                    drop_console: true
                }
            },
            plugin: {
                files: [{
                    expand: true,
                    cwd: 'build',
                    src: '**/*.js',
                    dest: 'build'
                }]
            }
        }
    });

    grunt.registerTask('default', ['coffeelint:app', 'coffee:all', 'copy:peg']);
    grunt.registerTask('release', ['default', 'copy:release', 'uglify:plugin']);
    grunt.registerTask('test', ['coffeelint:app', 'coffee:all', 'copy:peg', 'jasmine_node:unit']);
};
