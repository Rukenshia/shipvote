/******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, {
/******/ 				configurable: false,
/******/ 				enumerable: true,
/******/ 				get: getter
/******/ 			});
/******/ 		}
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "/dist/";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(__webpack_require__.s = 12);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ (function(module, exports) {

/*
	MIT License http://www.opensource.org/licenses/mit-license.php
	Author Tobias Koppers @sokra
*/
// css base code, injected by the css-loader
module.exports = function(useSourceMap) {
	var list = [];

	// return the list of modules as css string
	list.toString = function toString() {
		return this.map(function (item) {
			var content = cssWithMappingToString(item, useSourceMap);
			if(item[2]) {
				return "@media " + item[2] + "{" + content + "}";
			} else {
				return content;
			}
		}).join("");
	};

	// import a list of modules into the list
	list.i = function(modules, mediaQuery) {
		if(typeof modules === "string")
			modules = [[null, modules, ""]];
		var alreadyImportedModules = {};
		for(var i = 0; i < this.length; i++) {
			var id = this[i][0];
			if(typeof id === "number")
				alreadyImportedModules[id] = true;
		}
		for(i = 0; i < modules.length; i++) {
			var item = modules[i];
			// skip already imported module
			// this implementation is not 100% perfect for weird media query combinations
			//  when a module is imported multiple times with different media queries.
			//  I hope this will never occur (Hey this way we have smaller bundles)
			if(typeof item[0] !== "number" || !alreadyImportedModules[item[0]]) {
				if(mediaQuery && !item[2]) {
					item[2] = mediaQuery;
				} else if(mediaQuery) {
					item[2] = "(" + item[2] + ") and (" + mediaQuery + ")";
				}
				list.push(item);
			}
		}
	};
	return list;
};

function cssWithMappingToString(item, useSourceMap) {
	var content = item[1] || '';
	var cssMapping = item[3];
	if (!cssMapping) {
		return content;
	}

	if (useSourceMap && typeof btoa === 'function') {
		var sourceMapping = toComment(cssMapping);
		var sourceURLs = cssMapping.sources.map(function (source) {
			return '/*# sourceURL=' + cssMapping.sourceRoot + source + ' */'
		});

		return [content].concat(sourceURLs).concat([sourceMapping]).join('\n');
	}

	return [content].join('\n');
}

// Adapted from convert-source-map (MIT)
function toComment(sourceMap) {
	// eslint-disable-next-line no-undef
	var base64 = btoa(unescape(encodeURIComponent(JSON.stringify(sourceMap))));
	var data = 'sourceMappingURL=data:application/json;charset=utf-8;base64,' + base64;

	return '/*# ' + data + ' */';
}


/***/ }),
/* 1 */
/***/ (function(module, exports, __webpack_require__) {

/*
  MIT License http://www.opensource.org/licenses/mit-license.php
  Author Tobias Koppers @sokra
  Modified by Evan You @yyx990803
*/

var hasDocument = typeof document !== 'undefined'

if (typeof DEBUG !== 'undefined' && DEBUG) {
  if (!hasDocument) {
    throw new Error(
    'vue-style-loader cannot be used in a non-browser environment. ' +
    "Use { target: 'node' } in your Webpack config to indicate a server-rendering environment."
  ) }
}

var listToStyles = __webpack_require__(3)

/*
type StyleObject = {
  id: number;
  parts: Array<StyleObjectPart>
}

type StyleObjectPart = {
  css: string;
  media: string;
  sourceMap: ?string
}
*/

var stylesInDom = {/*
  [id: number]: {
    id: number,
    refs: number,
    parts: Array<(obj?: StyleObjectPart) => void>
  }
*/}

var head = hasDocument && (document.head || document.getElementsByTagName('head')[0])
var singletonElement = null
var singletonCounter = 0
var isProduction = false
var noop = function () {}
var options = null
var ssrIdKey = 'data-vue-ssr-id'

// Force single-tag solution on IE6-9, which has a hard limit on the # of <style>
// tags it will allow on a page
var isOldIE = typeof navigator !== 'undefined' && /msie [6-9]\b/.test(navigator.userAgent.toLowerCase())

module.exports = function (parentId, list, _isProduction, _options) {
  isProduction = _isProduction

  options = _options || {}

  var styles = listToStyles(parentId, list)
  addStylesToDom(styles)

  return function update (newList) {
    var mayRemove = []
    for (var i = 0; i < styles.length; i++) {
      var item = styles[i]
      var domStyle = stylesInDom[item.id]
      domStyle.refs--
      mayRemove.push(domStyle)
    }
    if (newList) {
      styles = listToStyles(parentId, newList)
      addStylesToDom(styles)
    } else {
      styles = []
    }
    for (var i = 0; i < mayRemove.length; i++) {
      var domStyle = mayRemove[i]
      if (domStyle.refs === 0) {
        for (var j = 0; j < domStyle.parts.length; j++) {
          domStyle.parts[j]()
        }
        delete stylesInDom[domStyle.id]
      }
    }
  }
}

function addStylesToDom (styles /* Array<StyleObject> */) {
  for (var i = 0; i < styles.length; i++) {
    var item = styles[i]
    var domStyle = stylesInDom[item.id]
    if (domStyle) {
      domStyle.refs++
      for (var j = 0; j < domStyle.parts.length; j++) {
        domStyle.parts[j](item.parts[j])
      }
      for (; j < item.parts.length; j++) {
        domStyle.parts.push(addStyle(item.parts[j]))
      }
      if (domStyle.parts.length > item.parts.length) {
        domStyle.parts.length = item.parts.length
      }
    } else {
      var parts = []
      for (var j = 0; j < item.parts.length; j++) {
        parts.push(addStyle(item.parts[j]))
      }
      stylesInDom[item.id] = { id: item.id, refs: 1, parts: parts }
    }
  }
}

function createStyleElement () {
  var styleElement = document.createElement('style')
  styleElement.type = 'text/css'
  head.appendChild(styleElement)
  return styleElement
}

function addStyle (obj /* StyleObjectPart */) {
  var update, remove
  var styleElement = document.querySelector('style[' + ssrIdKey + '~="' + obj.id + '"]')

  if (styleElement) {
    if (isProduction) {
      // has SSR styles and in production mode.
      // simply do nothing.
      return noop
    } else {
      // has SSR styles but in dev mode.
      // for some reason Chrome can't handle source map in server-rendered
      // style tags - source maps in <style> only works if the style tag is
      // created and inserted dynamically. So we remove the server rendered
      // styles and inject new ones.
      styleElement.parentNode.removeChild(styleElement)
    }
  }

  if (isOldIE) {
    // use singleton mode for IE9.
    var styleIndex = singletonCounter++
    styleElement = singletonElement || (singletonElement = createStyleElement())
    update = applyToSingletonTag.bind(null, styleElement, styleIndex, false)
    remove = applyToSingletonTag.bind(null, styleElement, styleIndex, true)
  } else {
    // use multi-style-tag mode in all other cases
    styleElement = createStyleElement()
    update = applyToTag.bind(null, styleElement)
    remove = function () {
      styleElement.parentNode.removeChild(styleElement)
    }
  }

  update(obj)

  return function updateStyle (newObj /* StyleObjectPart */) {
    if (newObj) {
      if (newObj.css === obj.css &&
          newObj.media === obj.media &&
          newObj.sourceMap === obj.sourceMap) {
        return
      }
      update(obj = newObj)
    } else {
      remove()
    }
  }
}

var replaceText = (function () {
  var textStore = []

  return function (index, replacement) {
    textStore[index] = replacement
    return textStore.filter(Boolean).join('\n')
  }
})()

function applyToSingletonTag (styleElement, index, remove, obj) {
  var css = remove ? '' : obj.css

  if (styleElement.styleSheet) {
    styleElement.styleSheet.cssText = replaceText(index, css)
  } else {
    var cssNode = document.createTextNode(css)
    var childNodes = styleElement.childNodes
    if (childNodes[index]) styleElement.removeChild(childNodes[index])
    if (childNodes.length) {
      styleElement.insertBefore(cssNode, childNodes[index])
    } else {
      styleElement.appendChild(cssNode)
    }
  }
}

function applyToTag (styleElement, obj) {
  var css = obj.css
  var media = obj.media
  var sourceMap = obj.sourceMap

  if (media) {
    styleElement.setAttribute('media', media)
  }
  if (options.ssrId) {
    styleElement.setAttribute(ssrIdKey, obj.id)
  }

  if (sourceMap) {
    // https://developer.chrome.com/devtools/docs/javascript-debugging
    // this makes source maps inside style tags work properly in Chrome
    css += '\n/*# sourceURL=' + sourceMap.sources[0] + ' */'
    // http://stackoverflow.com/a/26603875
    css += '\n/*# sourceMappingURL=data:application/json;base64,' + btoa(unescape(encodeURIComponent(JSON.stringify(sourceMap)))) + ' */'
  }

  if (styleElement.styleSheet) {
    styleElement.styleSheet.cssText = css
  } else {
    while (styleElement.firstChild) {
      styleElement.removeChild(styleElement.firstChild)
    }
    styleElement.appendChild(document.createTextNode(css))
  }
}


/***/ }),
/* 2 */
/***/ (function(module, exports) {

/* globals __VUE_SSR_CONTEXT__ */

// IMPORTANT: Do NOT use ES2015 features in this file.
// This module is a runtime utility for cleaner component module output and will
// be included in the final webpack user bundle.

module.exports = function normalizeComponent (
  rawScriptExports,
  compiledTemplate,
  functionalTemplate,
  injectStyles,
  scopeId,
  moduleIdentifier /* server only */
) {
  var esModule
  var scriptExports = rawScriptExports = rawScriptExports || {}

  // ES6 modules interop
  var type = typeof rawScriptExports.default
  if (type === 'object' || type === 'function') {
    esModule = rawScriptExports
    scriptExports = rawScriptExports.default
  }

  // Vue.extend constructor export interop
  var options = typeof scriptExports === 'function'
    ? scriptExports.options
    : scriptExports

  // render functions
  if (compiledTemplate) {
    options.render = compiledTemplate.render
    options.staticRenderFns = compiledTemplate.staticRenderFns
    options._compiled = true
  }

  // functional template
  if (functionalTemplate) {
    options.functional = true
  }

  // scopedId
  if (scopeId) {
    options._scopeId = scopeId
  }

  var hook
  if (moduleIdentifier) { // server build
    hook = function (context) {
      // 2.3 injection
      context =
        context || // cached call
        (this.$vnode && this.$vnode.ssrContext) || // stateful
        (this.parent && this.parent.$vnode && this.parent.$vnode.ssrContext) // functional
      // 2.2 with runInNewContext: true
      if (!context && typeof __VUE_SSR_CONTEXT__ !== 'undefined') {
        context = __VUE_SSR_CONTEXT__
      }
      // inject component styles
      if (injectStyles) {
        injectStyles.call(this, context)
      }
      // register component module identifier for async chunk inferrence
      if (context && context._registeredComponents) {
        context._registeredComponents.add(moduleIdentifier)
      }
    }
    // used by ssr in case component is cached and beforeCreate
    // never gets called
    options._ssrRegister = hook
  } else if (injectStyles) {
    hook = injectStyles
  }

  if (hook) {
    var functional = options.functional
    var existing = functional
      ? options.render
      : options.beforeCreate

    if (!functional) {
      // inject component registration as beforeCreate hook
      options.beforeCreate = existing
        ? [].concat(existing, hook)
        : [hook]
    } else {
      // for template-only hot-reload because in that case the render fn doesn't
      // go through the normalizer
      options._injectStyles = hook
      // register for functioal component in vue file
      options.render = function renderWithStyleInjection (h, context) {
        hook.call(context)
        return existing(h, context)
      }
    }
  }

  return {
    esModule: esModule,
    exports: scriptExports,
    options: options
  }
}


/***/ }),
/* 3 */
/***/ (function(module, exports) {

/**
 * Translates the list format produced by css-loader into something
 * easier to manipulate.
 */
module.exports = function listToStyles (parentId, list) {
  var styles = []
  var newStyles = {}
  for (var i = 0; i < list.length; i++) {
    var item = list[i]
    var id = item[0]
    var css = item[1]
    var media = item[2]
    var sourceMap = item[3]
    var part = {
      id: parentId + ':' + i,
      css: css,
      media: media,
      sourceMap: sourceMap
    }
    if (!newStyles[id]) {
      styles.push(newStyles[id] = { id: id, parts: [part] })
    } else {
      newStyles[id].parts.push(part)
    }
  }
  return styles
}


/***/ }),
/* 4 */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "a", function() { return BASE_URL; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "b", function() { return BASE_WS_URL; });
var BASE_URL = "https://shipvote.in.fkn.space";
var BASE_WS_URL = "wss://shipvote.in.fkn.space";
// export const BASE_URL = 'http://localhost:4000';
// export const BASE_WS_URL = 'ws://localhost:4000';

/***/ }),
/* 5 */,
/* 6 */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_0__shipvote__ = __webpack_require__(4);
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//



var _window$axios = window.axios,
    get = _window$axios.get,
    post = _window$axios.post,
    put = _window$axios.put;


window.App = {
  name: 'app',
  data: function data() {
    return {
      loading: true,
      saving: false,
      loadingError: false,

      error: undefined,
      validations: {
        username: true,
        realm: true
      },

      configured: false,
      token: '',
      theme: 'light',
      config: {}
    };
  },
  created: function created() {
    var _this = this;

    window.Twitch.ext.onContext(function (ctx) {
      _this.theme = ctx.theme;
    });

    window.Twitch.ext.onAuthorized(function (data) {
      _this.config.id = data.channelId;
      _this.token = data.token;

      get(__WEBPACK_IMPORTED_MODULE_0__shipvote__["a" /* BASE_URL */] + '/api/settings/channels/' + data.channelId, {
        headers: {
          authorization: 'Bearer ' + data.token
        }
      }).then(function (res) {
        _this.loading = false;
        _this.configured = true;

        _this.config = res.data['data'];
      }).catch(function (e) {
        if (e.response.status === 404) {
          _this.loading = false;
          _this.config = {
            id: data.channelId,
            wows_username: '',
            wows_realm: 'eu',
            ships: []
          };
        } else {
          _this.loadingError = true;
          _this.loading = false;
        }
      });
    });
  },

  methods: {
    updateInfo: function updateInfo() {
      var _this2 = this;

      this.error = undefined;
      this.validations.username = true;
      this.validations.realm = true;
      this.saving = true;

      put(__WEBPACK_IMPORTED_MODULE_0__shipvote__["a" /* BASE_URL */] + '/api/settings/channels/' + this.config.id, {
        channel: this.config
      }, {
        headers: {
          authorization: 'Bearer ' + this.token
        }
      }).then(function (res) {
        _this2.loading = false;

        _this2.config = res.data['data'];
      }).catch(function (res) {
        _this2.error = 'could not save information';

        if (res.response.status === 404) {
          _this2.validations.username = false;
          _this2.validations.realm = false;
          _this2.error = 'Please check your username and realm';
        }
      }).then(function () {
        _this2.saving = false;
      });
    },
    createInfo: function createInfo() {
      var _this3 = this;

      this.error = undefined;
      this.validations.username = true;
      this.validations.realm = true;
      this.saving = true;

      post(__WEBPACK_IMPORTED_MODULE_0__shipvote__["a" /* BASE_URL */] + '/api/settings/channels', this.config, {
        headers: {
          authorization: 'Bearer ' + this.token
        }
      }).then(function (res) {
        _this3.loading = false;

        _this3.config = res.data['data'];
        _this3.configured = true;
      }).catch(function (res) {
        _this3.error = 'could not save information';

        if (res.response.status === 404) {
          _this3.validations.username = false;
          _this3.validations.realm = false;
          _this3.error = 'Please check your username and realm';
        }
      }).then(function () {
        _this3.saving = false;
      });
    },
    toggleShip: function toggleShip(ship) {
      var _this4 = this;

      var newState = !ship.enabled;

      this.error = undefined;

      console.log(this.token);

      put(__WEBPACK_IMPORTED_MODULE_0__shipvote__["a" /* BASE_URL */] + '/api/settings/channels/' + this.config.id + '/ships/' + ship.id + '/enabled', { enabled: newState }, {
        headers: {
          authorization: 'Bearer ' + this.token
        }
      }).then(function () {
        ship.enabled = newState;
      }).catch(function (res) {
        _this4.error = 'could not write ship information';
      });
    }
  },
  computed: {
    enabledShips: function enabledShips() {
      return this.config.ships.filter(function (s) {
        return s.enabled === true;
      });
    }
  }
};
/* harmony default export */ __webpack_exports__["a"] = (window.App);

/***/ }),
/* 7 */,
/* 8 */,
/* 9 */,
/* 10 */,
/* 11 */,
/* 12 */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
Object.defineProperty(__webpack_exports__, "__esModule", { value: true });
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_0__babel_loader_node_modules_vue_loader_lib_selector_type_script_index_0_App_vue__ = __webpack_require__(6);
/* empty harmony namespace reexport */
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_1__node_modules_vue_loader_lib_template_compiler_index_id_data_v_55e235b1_hasScoped_false_buble_transforms_node_modules_vue_loader_lib_selector_type_template_index_0_App_vue__ = __webpack_require__(15);
function injectStyle (ssrContext) {
  __webpack_require__(13)
}
var normalizeComponent = __webpack_require__(2)
/* script */


/* template */

/* template functional */
var __vue_template_functional__ = false
/* styles */
var __vue_styles__ = injectStyle
/* scopeId */
var __vue_scopeId__ = null
/* moduleIdentifier (server only) */
var __vue_module_identifier__ = null
var Component = normalizeComponent(
  __WEBPACK_IMPORTED_MODULE_0__babel_loader_node_modules_vue_loader_lib_selector_type_script_index_0_App_vue__["a" /* default */],
  __WEBPACK_IMPORTED_MODULE_1__node_modules_vue_loader_lib_template_compiler_index_id_data_v_55e235b1_hasScoped_false_buble_transforms_node_modules_vue_loader_lib_selector_type_template_index_0_App_vue__["a" /* default */],
  __vue_template_functional__,
  __vue_styles__,
  __vue_scopeId__,
  __vue_module_identifier__
)

/* harmony default export */ __webpack_exports__["default"] = (Component.exports);


/***/ }),
/* 13 */
/***/ (function(module, exports, __webpack_require__) {

// style-loader: Adds some css to the DOM by adding a <style> tag

// load the styles
var content = __webpack_require__(14);
if(typeof content === 'string') content = [[module.i, content, '']];
if(content.locals) module.exports = content.locals;
// add the styles to the DOM
var update = __webpack_require__(1)("a5bfb16c", content, true, {});

/***/ }),
/* 14 */
/***/ (function(module, exports, __webpack_require__) {

exports = module.exports = __webpack_require__(0)(false);
// imports
exports.push([module.i, "@import url(https://fonts.googleapis.com/css?family=Roboto);", ""]);

// module
exports.push([module.i, "\n.mdc-text-field--box {\n  margin-top: 0;\n}\n.dark {\n  background-color: #201c2b;\n  color: #e5e3e8;\n}\n.dark a {\n    color: #e2dbf0;\n}\n.dark .mdc-card .mdc-card__supporting-text {\n    color: #e5e3e8;\n}\n.dark .mdc-card.mdc-card--flat {\n    background-color: #6441a4;\n    color: inherit;\n}\n.dark .mdc-tab--active .mdc-tab__text-label {\n    color: #6441a4;\n}\n.dark .mdc-tab__text-label {\n    color: #e5e3e8;\n}\n.dark .mdc-form-field > label {\n    color: #e2dbf0;\n}\n.dark .mdc-text-field, .dark .mdc-select {\n    background-color: #6441a4;\n}\n.dark .mdc-text-field label, .dark .mdc-select label {\n      color: #e2dbf0 !important;\n}\n.dark .mdc-text-field input, .dark .mdc-text-field select, .dark .mdc-select input, .dark .mdc-select select {\n      color: #e5e3e8 !important;\n}\n.dark .mdc-button.mdc-button--outlined {\n    border-color: #e2dbf0;\n    color: #e2dbf0;\n}\n.dark .mdc-list {\n    color: inherit;\n}\n.dark .mdc-list .mdc-list-item .mdc-list-item__secondary-text {\n      color: #e2dbf0;\n}\n.dark .vote-notice .cta {\n    background-color: #6441a4;\n}\n.dark .selection .card {\n    background-color: #201c2b;\n}\n.dark .selection .card .ship {\n      background-color: #6441a4;\n      border-color: #6441a4;\n}\n.dark .selection .card .ship .vote-button {\n        background-color: #e5e3e8;\n        color: #6441a4;\n}\n.dark .selection .card .ship .progress-bar .progress {\n        background-color: rgba(255, 255, 255, 0.5);\n}\n.typography {\n  font-family: Roboto, sans-serif;\n}\n.typography__color--warning {\n  color: orange;\n}\n.typography__color--success {\n  color: #3fc380;\n}\n.typography__color--error {\n  color: #d24d57;\n}\n.typography--headline1 {\n  font-size: 20px;\n  font-weight: bold;\n  display: block;\n}\n.typography--subtitle {\n  color: #3f3f3f;\n}\n.card {\n  background-color: #ffffff;\n  border-radius: 4px;\n  padding: 8px 12px;\n  overflow: hidden;\n}\n.card .card__divider {\n    height: 12px;\n}\n.raised {\n  box-shadow: 0px 3px 1px -2px rgba(0, 0, 0, 0.2), 0px 2px 2px 0px rgba(0, 0, 0, 0.14), 0px 1px 5px 0px rgba(0, 0, 0, 0.12);\n}\n:root {\n  --mdc-theme-secondary: #6441a4;\n  --mdc-theme-primary: #6441a4;\n}\n.mdc-card.mdc-card--flat {\n  padding: 4px;\n  box-shadow: none;\n  border-radius: 8px;\n  background-color: #f8f9fa;\n  color: #5f6368;\n}\n.mdc-list.mdc-list--bordered li:first-child {\n  border-top-left-radius: 8px;\n  border-top-right-radius: 8px;\n}\n.mdc-list.mdc-list--bordered li:last-child {\n  border-bottom-left-radius: 8px;\n  border-bottom-right-radius: 8px;\n}\n.mdc-list .mdc-list-item {\n  padding-top: 16px;\n}\n.fullwidth,\n.fullwidth .mdc-textfield {\n  width: 100%;\n}\n", ""]);

// exports


/***/ }),
/* 15 */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
var render = function () {var _vm=this;var _h=_vm.$createElement;var _c=_vm._self._c||_h;return _c('mdc-layout-grid',{class:_vm.theme},[_c('mdc-layout-cell',{attrs:{"span":12}},[_c('mdc-card',{staticClass:"mdc-card--flat"},[_c('mdc-card-text',{staticStyle:{"padding-left":"16px"}},[_c('mdc-body',[_vm._v("\n          Learn how to use this extension\n          "),_c('a',{attrs:{"target":"_blank","href":"https://shipvote.in.fkn.space/getting-started"}},[_vm._v("here")]),_vm._v(".\n        ")])],1)],1),_vm._v(" "),_c('mdc-headline',[_vm._v("Shipvote Settings")]),_vm._v(" "),(_vm.loading)?_c('mdc-layout-grid',[_c('mdc-layout-cell',{attrs:{"span":4}},[_c('mdc-body',{attrs:{"typo":"body2"}},[_vm._v("Loading your config")]),_vm._v(" "),_c('mdc-linear-progress',{attrs:{"indeterminate":""}})],1)],1):_vm._e(),_vm._v(" "),(_vm.loadingError)?_c('mdc-layout-grid',[_c('mdc-layout-cell',{attrs:{"span":4}},[_c('mdc-body',{attrs:{"typo":"body1"}},[_vm._v("Configuration could not be loaded. Please contact rukenshia for support.")])],1)],1):_vm._e(),_vm._v(" "),(!_vm.loading && !_vm.loadingError)?_c('mdc-layout-grid',[_c('mdc-layout-cell',{attrs:{"span":12}},[_c('mdc-layout-grid',[_c('mdc-layout-cell',{attrs:{"phone":4,"desktop":4,"tablet":4}},[_c('mdc-textfield',{staticClass:"fullwidth",attrs:{"label":"WoWS Username","valid":_vm.validations.username,"required":"","box":""},model:{value:(_vm.config.wows_username),callback:function ($$v) {_vm.$set(_vm.config, "wows_username", $$v)},expression:"config.wows_username"}})],1),_vm._v(" "),_c('mdc-layout-cell',{attrs:{"phone":4,"desktop":2,"tablet":2}},[_c('mdc-select',{staticClass:"fullwidth",attrs:{"label":"WoWS Server","valid":_vm.validations.realm},model:{value:(_vm.config.wows_realm),callback:function ($$v) {_vm.$set(_vm.config, "wows_realm", $$v)},expression:"config.wows_realm"}},[_c('option',[_vm._v("eu")]),_vm._v(" "),_c('option',[_vm._v("na")]),_vm._v(" "),_c('option',[_vm._v("asia")]),_vm._v(" "),_c('option',[_vm._v("ru")])])],1),_vm._v(" "),(_vm.configured)?_c('mdc-layout-cell',{attrs:{"span":12}},[_c('mdc-button',{attrs:{"raised":"","disabled":_vm.saving},on:{"click":_vm.updateInfo}},[_vm._v("Save")]),_vm._v(" "),_c('mdc-button',{attrs:{"outlined":"","disabled":_vm.saving},on:{"click":_vm.updateInfo}},[_vm._v("Refresh ships")]),_vm._v(" "),(_vm.error)?_c('mdc-body',[_vm._v("An error occured: "+_vm._s(_vm.error))]):_vm._e()],1):_vm._e(),_vm._v(" "),(!_vm.configured)?_c('mdc-layout-cell',{attrs:{"span":12}},[_c('mdc-button',{attrs:{"raised":"","disabled":_vm.config.wows_username === '' || _vm.saving},on:{"click":_vm.createInfo}},[_vm._v("Setup")]),_vm._v(" "),(_vm.error)?_c('mdc-body',[_vm._v("An error occured: "+_vm._s(_vm.error))]):_vm._e()],1):_vm._e()],1),_vm._v(" "),(_vm.configured)?[_c('mdc-body',{attrs:{"typo":"body1"}},[_vm._v("\n            You currently own "+_vm._s(_vm.config.ships.length)+" ships. "+_vm._s(_vm.enabledShips.length)+" ships are currently enabled.\n            Please reload your live dashboard after enabling/disabling ships to apply them to your next vote.\n          ")]),_vm._v(" "),_c('mdc-list',{attrs:{"two-line":"","bordered":""}},_vm._l((_vm.config.ships),function(ship){return _c('mdc-list-item',{key:ship.id},[_c('img',{attrs:{"slot":"start-detail","src":ship.image,"width":"56","height":"auto","alt":("Image of " + (ship.name))},slot:"start-detail"}),_vm._v(" "),_c('span',[_c('strong',[_vm._v(_vm._s(ship.name))])]),_vm._v(" "),_c('span',{attrs:{"slot":"secondary"},slot:"secondary"},[_vm._v("Tier: "+_vm._s(ship.tier)+", Nation: "+_vm._s(ship.nation))]),_vm._v(" "),_c('mdc-button',{attrs:{"slot":"end-detail","raised":!ship.enabled},on:{"click":function($event){_vm.toggleShip(ship)}},slot:"end-detail"},[_vm._v(_vm._s(ship.enabled ? 'disable' : 'enable'))])],1)}))]:_vm._e()],2)],1):_vm._e()],1)],1)}
var staticRenderFns = []
var esExports = { render: render, staticRenderFns: staticRenderFns }
/* harmony default export */ __webpack_exports__["a"] = (esExports);

/***/ })
/******/ ]);