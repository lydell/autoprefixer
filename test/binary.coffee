autoprefixer = require('../lib/autoprefixer')
Binary       = require('../lib/autoprefixer/binary')

fs    = require('fs-extra')
child = require('child_process')

class StringBuffer
  constructor: -> @content  = ''
  write: (str) -> @content += str
  resume:      -> @resumed  = true
  on: (event, callback) ->
    if event == 'data' and @resumed
      callback(@content)
    else if event == 'end'
      callback()

tempDir = __dirname + '/fixtures'

write = (file, css) ->
  fs.mkdirSync(tempDir) unless fs.existsSync(tempDir)
  fs.writeFileSync("#{tempDir}/#{file}", css)

read = (file) ->
  fs.readFileSync("#{tempDir}/#{file}").toString()

describe 'Binary', ->
  beforeEach ->
    @stdout = new StringBuffer()
    @stderr = new StringBuffer()
    @stdin  = new StringBuffer()

    @exec = (args..., callback) ->
      args = args.map (i) ->
        if i.match(/\.css/)
          "#{tempDir}/#{i}"
        else
          i

      binary = new Binary
        argv:   ['', ''].concat(args)
        stdin:  @stdin
        stdout: @stdout
        stderr: @stderr

      binary.run =>
        if binary.status == 0 and @stderr.content == ''
          error = false
        else
          error = @stderr.content
        callback(@stdout.content, error)

  afterEach ->
    fs.removeSync(tempDir) if fs.existsSync(tempDir)

  css      = 'a { transition: all 1s; }'
  prefixed = "a {\n  -webkit-transition: all 1s;\n  transition: all 1s;\n}"

  it 'shows autoprefixer version', (done) ->
    @exec '-v', (out, err) ->
      err.should.be.false
      out.should.match(/^autoprefixer [\d\.]+\n$/)
      done()

  it 'shows help instructions', (done) ->
    @exec '-h', (out, err) ->
      err.should.be.false
      out.should.match(/Usage:/)
      done()

  it 'shows selected browsers and properties', (done) ->
    @exec '-i', (out, err) ->
      err.should.be.false
      out.should.match(/Browsers:/)
      done()

  it 'changes browsers', (done) ->
    @exec '-i', '-b', 'ie 6', (out, err) ->
      out.should.match(/IE: 6/)
      done()

  it 'rewrites several files', (done) ->
    write('a.css', css)
    write('b.css', css + css)
    @exec '-b', 'chrome 25', 'a.css', 'b.css', (out, err) ->
      err.should.be.false
      out.should.eql ''
      read('a.css').should.eql prefixed
      read('b.css').should.eql prefixed + "\n\n" + prefixed
      done()

  it 'changes output file', (done) ->
    write('a.css', css)
    @exec '-b', 'chrome 25', 'a.css', '-o', 'b.css', (out, err) ->
      err.should.be.false
      out.should.eql ''
      read('a.css').should.eql css
      read('b.css').should.eql prefixed
      done()

  it 'concats several files to one output', (done) ->
    write('a.css', css)
    write('b.css', 'a { color: black; }')
    @exec '-b', 'chrome 25', 'a.css', 'b.css', '-o', 'c.css', (out, err) ->
      err.should.be.false
      out.should.eql ''
      read('c.css').should.eql prefixed + "\n\n" + "a {\n  color: black;\n}"
      done()

  it 'outputs to stdout', (done) ->
    write('a.css', css)
    @exec '-b', 'chrome 25', '-o', '-', 'a.css', (out, err) ->
      err.should.be.false
      out.should.eql prefixed + "\n"
      read('a.css').should.eql css
      done()

  it 'reads from stdin', (done) ->
    @stdin.content = css
    @exec '-b', 'chrome 25', (out, err) ->
      err.should.be.false
      out.should.eql prefixed + "\n"
      done()

  it "raises an error when files doesn't exists", (done) ->
    @exec 'nonexistent.file', (out, err) ->
      out.should.be.empty
      err.should.match(/autoprefixer: .* no such file .*nonexistent\.file/)
      done()

  it 'raises an error when unknown arguments are given', (done) ->
    @exec '-x', (out, err) ->
      out.should.be.empty
      err.should.match(/autoprefixer: Unknown argument -x/)
      done()

  it 'prints errors', (done) ->
    @exec '-b', 'ie', (out, err) ->
      out.should.be.empty
      err.should.eql("autoprefixer: Unknown browser requirement `ie`\n")
      done()

  it 'prints parsing errors', (done) ->
    @stdin.content = 'a {'
    @exec '-b', 'chrome 25', (out, err) ->
      out.should.be.empty
      err.should.match(/^autoprefixer: Can't parse CSS/)
      done()

  it "doesn't care about `-m` if `-o` isn't set", (done) ->
    write('a.css', css)
    @exec '-b', 'chrome 25', 'a.css', '-m', (out, err) ->
      err.should.be.false
      out.should.be.empty
      read('a.css').should.eql prefixed
      fs.existsSync('a.css.map').should.be.false
      done()

  it "doesn't care about `-m` it outputting to stdout", (done) ->
    write('a.css', css)
    @exec '-b', 'chrome 25', 'a.css', '-o', '-', '-m', (out, err) ->
      err.should.be.false
      out.should.eql prefixed + "\n"
      fs.existsSync('-.map').should.be.false
      done()

  it 'generates source maps', (done) ->
    write('a.css', css)
    @exec '-b', 'chrome 25', 'a.css', '-o', 'b.css', '-m', (out, err) ->
      err.should.be.false
      out.should.be.empty
      read('b.css').should.eql prefixed + "\n/*# sourceMappingURL=b.css.map */"
      JSON.parse(read('b.css.map')).should.eql
        version: 3
        file: 'b.css'
        sources: ['a.css']
        names: []
        mappings: 'AAAA;EAAI,0BAAkB;EAAlB,kBAAkB'
      done()

describe 'bin/autoprefixer', ->

  it 'is an executable', (done) ->
    binary = __dirname + '/../bin/autoprefixer'
    child.execFile binary, ['-v'], { }, (error, out) ->
      (!!error).should.be.false
      out.should.match(/^autoprefixer [\d\.]+\n$/)
      done()
