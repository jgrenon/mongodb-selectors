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
        }
    });

    grunt.registerTask('default', ['coffeelint:app', 'coffee:all', 'copy:peg']);
    grunt.registerTask('test', ['coffeelint:app', 'coffee:all', 'copy:peg', 'jasmine_node:unit']);
};
