// Taken from
// https://github.com/paulirish/headless-cat-n-mouse/blob/master/apply-evasions.js
// https://intoli.com/blog/not-possible-to-block-chrome-headless

c = 0

if (c == 0) {
  console.log("Running init script")
  // Pass the User-Agent Test.

  userAgent =
    'Mozilla/5.0 (X11; Linux x86_64)' +
    'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.39 Safari/537.36';

  Object.defineProperty(navigator, 'userAgent', {
    get: () => userAgent
  });

  // Pass the Webdriver Test.
  newProto = navigator.__proto__;
  delete newProto.webdriver;
  navigator.__proto__ = newProto;

  // Pass the Chrome Test.
  window.chrome = {
    runtime: {}
  };

  const originalQuery = window.navigator.permissions.query;
  window.navigator.permissions.__proto__.query = parameters =>
    parameters.name === 'notifications'
      ? Promise.resolve({ state: Notification.permission })
      : originalQuery(parameters);

  // Inspired by: https://github.com/ikarienator/phantomjs_hide_and_seek/blob/master/5.spoofFunctionBind.js
  const oldCall = Function.prototype.call;
  function call() {
    return oldCall.apply(this, arguments);
  }

  Function.prototype.call = call;

  const nativeToStringFunctionString = Error.toString().replace(/Error/g, "toString");
  const oldToString = Function.prototype.toString;

  function functionToString() {
    if (this === window.navigator.permissions.query) {
      return "function query() { [native code] }";
    }
    if (this === functionToString) {
      return nativeToStringFunctionString;
    }
    return oldCall.call(oldToString, this);
  }
  Function.prototype.toString = functionToString;

  // Pass the Languages Test.
  // Overwrite the `plugins` property to use a custom getter.
  Object.defineProperty(navigator, 'languages', {
    get: () => ['en-US', 'en']
  });

  // Pass the iframe Test
  Object.defineProperty(HTMLIFrameElement.prototype, 'contentWindow', {
    get: function () {
      return window;
    }
  });

  // Pass toString test, though it breaks console.debug() from working
  window.console.debug = () => {
    return null;
  };

  // https://github.com/berstend/puppeteer-extra/blob/master/packages/puppeteer-extra-plugin-stealth/evasions/navigator.plugins/index.js
  function mockPluginsAndMimeTypes() {
    /* global MimeType MimeTypeArray PluginArray */

    // Disguise custom functions as being native
    const makeFnsNative = (fns = []) => {
      const oldCall = Function.prototype.call
      function call() {
        return oldCall.apply(this, arguments)
      }
      // eslint-disable-next-line
      Function.prototype.call = call

      const nativeToStringFunctionString = Error.toString().replace(
        /Error/g,
        'toString'
      )
      const oldToString = Function.prototype.toString

      function functionToString() {
        for (const fn of fns) {
          if (this === fn.ref) {
            return `function ${fn.name}() { [native code] }`
          }
        }

        if (this === functionToString) {
          return nativeToStringFunctionString
        }
        return oldCall.call(oldToString, this)
      }
      // eslint-disable-next-line
      Function.prototype.toString = functionToString
    }

    const mockedFns = []

    const fakeData = {
      mimeTypes: [
        {
          type: 'application/pdf',
          suffixes: 'pdf',
          description: '',
          __pluginName: 'Chrome PDF Viewer'
        },
        {
          type: 'application/x-google-chrome-pdf',
          suffixes: 'pdf',
          description: 'Portable Document Format',
          __pluginName: 'Chrome PDF Plugin'
        },
        {
          type: 'application/x-nacl',
          suffixes: '',
          description: 'Native Client Executable',
          enabledPlugin: Plugin,
          __pluginName: 'Native Client'
        },
        {
          type: 'application/x-pnacl',
          suffixes: '',
          description: 'Portable Native Client Executable',
          __pluginName: 'Native Client'
        }
      ],
      plugins: [
        {
          name: 'Chrome PDF Plugin',
          filename: 'internal-pdf-viewer',
          description: 'Portable Document Format'
        },
        {
          name: 'Chrome PDF Viewer',
          filename: 'mhjfbmdgcfjbbpaeojofohoefgiehjai',
          description: ''
        },
        {
          name: 'Native Client',
          filename: 'internal-nacl-plugin',
          description: ''
        }
      ],
      fns: {
        namedItem: instanceName => {
          // Returns the Plugin/MimeType with the specified name.
          const fn = function (name) {
            if (!arguments.length) {
              throw new TypeError(
                `Failed to execute 'namedItem' on '${instanceName}': 1 argument required, but only 0 present.`
              )
            }
            return this[name] || null
          }
          mockedFns.push({ ref: fn, name: 'namedItem' })
          return fn
        },
        item: instanceName => {
          // Returns the Plugin/MimeType at the specified index into the array.
          const fn = function (index) {
            if (!arguments.length) {
              throw new TypeError(
                `Failed to execute 'namedItem' on '${instanceName}': 1 argument required, but only 0 present.`
              )
            }
            return this[index] || null
          }
          mockedFns.push({ ref: fn, name: 'item' })
          return fn
        },
        refresh: instanceName => {
          // Refreshes all plugins on the current page, optionally reloading documents.
          const fn = function () {
            return undefined
          }
          mockedFns.push({ ref: fn, name: 'refresh' })
          return fn
        }
      }
    }
    // Poor mans _.pluck
    const getSubset = (keys, obj) =>
      keys.reduce((a, c) => ({ ...a, [c]: obj[c] }), {})

    function generateMimeTypeArray() {
      const arr = fakeData.mimeTypes
        .map(obj => getSubset(['type', 'suffixes', 'description'], obj))
        .map(obj => Object.setPrototypeOf(obj, MimeType.prototype))
      arr.forEach(obj => {
        arr[obj.type] = obj
      })

      // Mock functions
      arr.namedItem = fakeData.fns.namedItem('MimeTypeArray')
      arr.item = fakeData.fns.item('MimeTypeArray')

      return Object.setPrototypeOf(arr, MimeTypeArray.prototype)
    }

    const mimeTypeArray = generateMimeTypeArray()
    Object.defineProperty(navigator, 'mimeTypes', {
      get: () => mimeTypeArray
    })

    function generatePluginArray() {
      const arr = fakeData.plugins
        .map(obj => getSubset(['name', 'filename', 'description'], obj))
        .map(obj => {
          const mimes = fakeData.mimeTypes.filter(
            m => m.__pluginName === obj.name
          )
          // Add mimetypes
          mimes.forEach((mime, index) => {
            navigator.mimeTypes[mime.type].enabledPlugin = obj
            obj[mime.type] = navigator.mimeTypes[mime.type]
            obj[index] = navigator.mimeTypes[mime.type]
          })
          obj.length = mimes.length
          return obj
        })
        .map(obj => {
          // Mock functions
          obj.namedItem = fakeData.fns.namedItem('Plugin')
          obj.item = fakeData.fns.item('Plugin')
          return obj
        })
        .map(obj => Object.setPrototypeOf(obj, Plugin.prototype))
      arr.forEach(obj => {
        arr[obj.name] = obj
      })

      // Mock functions
      arr.namedItem = fakeData.fns.namedItem('PluginArray')
      arr.item = fakeData.fns.item('PluginArray')
      arr.refresh = fakeData.fns.refresh('PluginArray')

      return Object.setPrototypeOf(arr, PluginArray.prototype)
    }

    const pluginArray = generatePluginArray()
    Object.defineProperty(navigator, 'plugins', {
      get: () => pluginArray
    })

    // Make mockedFns toString() representation resemble a native function
    makeFnsNative(mockedFns)
  }
  try {
    const isPluginArray = navigator.plugins instanceof PluginArray
    const hasPlugins = isPluginArray && navigator.plugins.length > 0
    if (isPluginArray && hasPlugins) {
      return // nothing to do here
    }
    mockPluginsAndMimeTypes()
  } catch (err) {
    console.log("ERRR", err)
  }
}
