// CodeMirror log mode
// Distributed under an MIT license: https://codemirror.net/5/LICENSE
// Supports log output with level and category highlighting

(function(mod) {
  if (typeof exports == "object" && typeof module == "object") // CommonJS
    mod(require("../../lib/codemirror"));
  else if (typeof define == "function" && define.amd) // AMD
    define(["../../lib/codemirror"], mod);
  else // Plain browser env
    mod(CodeMirror);
})(function(CodeMirror) {
"use strict";

CodeMirror.defineMode("log", function(config, parserConfig) {
  return {
    startState: function(basecol) {
      return {
        basecol: basecol || 0,
        tabDone: false
      };
    },

    token: function(stream, state) {
      if (stream.sol()) {
        state.tabDone = false;
        
        if (stream.match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)) {
          return "log-timestamp";
        }
      }

      if (stream.eatSpace()) return null;

      var ch = stream.peek();

      if (!ch) {
        stream.skipToEnd();
        return null;
      }

      if (ch === '【') {
        if (stream.match(/【[^】]*】/)) {
          return "log-bracket";
        }
      }

      if (state.tabDone) {
        stream.next();
        return "log-string";
      }

      if (ch === '[' && window.levelTranslations) {
        for (var levelKey in window.levelTranslations) {
          var levelText = '[' + window.levelTranslations[levelKey] + ']';
          if (stream.match(levelText)) {
            return "log-level-" + levelKey;
          }
        }
      }

      if (ch === '[' && stream.match(/\[[A-Z][^\]]*\]/)) {
        return "log-category";
      }

      if (ch !== '[') {
        state.tabDone = true;
      }

      stream.next();
      return "log-string";
    }
  };
});

CodeMirror.defineMIME("text/x-log", "log");

});

(function() {
  function initLogLevelWidth() {
    if (!window.levelTranslations) return;
    
    var tempContainer = document.createElement('div');
    tempContainer.style.position = 'absolute';
    tempContainer.style.visibility = 'hidden';
    tempContainer.style.whiteSpace = 'nowrap';
    tempContainer.style.fontSize = '15px';
    tempContainer.style.fontWeight = '600';
    tempContainer.style.fontFamily = 'Consolas, Menlo, Monaco, Lucida Console, Liberation Mono, DejaVu Sans Mono, Bitstream Vera Sans Mono, Courier New, monospace, sans-serif';
    tempContainer.style.padding = '0px 5px';
    document.body.appendChild(tempContainer);
    
    let maxWidth = 0;
    
    for (var levelKey in window.levelTranslations) {
      var translatedText = '[' + window.levelTranslations[levelKey] + ']';
      tempContainer.textContent = translatedText;
      var width = tempContainer.offsetWidth;
      if (width > maxWidth) {
        maxWidth = width;
      }
    }
    
    document.body.removeChild(tempContainer);
    
    if (maxWidth > 0) {
      document.documentElement.style.setProperty('--log-level-width', maxWidth + 'px');
    }
  }
  
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initLogLevelWidth);
  } else {
    initLogLevelWidth();
  }
})();
