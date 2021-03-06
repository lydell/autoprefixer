Browsers = require('../lib/browsers')
Prefixes = require('../lib/prefixes')
info     = require('../lib/info')

data =
  browsers:
    chrome:
      prefix:   '-webkit-'
      versions: ['chrome 1']
    ff:
      prefix:   '-moz-'
      versions: ['ff 2', 'ff 1']
    ie:
      prefix:   '-ms-'
      versions: ['ie 2']
  prefixes:
    a:
      browsers: ['ff 2', 'ff 1', 'chrome 1']
      transition: true
    b:
      browsers: ['ie 2', 'ff 1']
      props:    ['a', '*']
    c:
      browsers: ['ff 2']
      props:    ['c']
    d:
      browsers: ['ff 2']
      selector:   true
    '@keyframes':
      browsers: ['ff 2']
    transition:
      browsers: ['ff 2']

describe 'info', ->

  it 'returns selected browsers and prefixes', ->
    browsers = new Browsers(data.browsers, ['chrome 1', 'ff 2', 'ff 1', 'ie 2'])
    prefixes = new Prefixes(data.prefixes, browsers)

    info(prefixes).should.eql "Browsers:\n" +
                              "  Chrome: 1\n" +
                              "  Firefox: 2, 1\n" +
                              "  IE: 2\n" +
                              "\n" +
                              "At-Rules:\n" +
                              "  @keyframes: moz\n" +
                              "\n" +
                              "Selectors:\n" +
                              "  d: moz\n" +
                              "\n" +
                              "Properties:\n" +
                              "  transition: moz\n" +
                              "  a*: webkit, moz\n" +
                              "  * - can be used in transition\n" +
                              "\n" +
                              "Values:\n" +
                              "  b: moz, ms\n" +
                              "  c: moz\n"

  it "doesn't show transitions unless they are necessary", ->
    browsers = new Browsers(data.browsers, ['chrome 1', 'ff 1', 'ie 2'])
    prefixes = new Prefixes(data.prefixes, browsers)

    info(prefixes).should.eql "Browsers:\n" +
                              "  Chrome: 1\n" +
                              "  Firefox: 1\n" +
                              "  IE: 2\n" +
                              "\n" +
                              "Properties:\n" +
                              "  a: webkit, moz\n" +
                              "\n" +
                              "Values:\n" +
                              "  b: moz, ms\n"

  it 'returns string for empty prefixes', ->
    browsers = new Browsers(data.browsers, ['ie 1'])
    prefixes = new Prefixes(data.prefixes, browsers)

    info(prefixes).should.eql "Browsers:\n" +
                                 "  IE: 1\n"

  it 'returns string for empty browsers', ->
    browsers = new Browsers(data.browsers, [])
    prefixes = new Prefixes(data.prefixes, browsers)

    info(prefixes).should.eql "No browsers selected"
