//>>built
define("xstyle/core/base","xstyle/core/elemental xstyle/core/expression xstyle/core/utils put-selector/put xstyle/core/Rule xstyle/core/observe".split(" "),function(r,s,h,m,f,n){function p(a,c){return{forElement:function(b,d){var e=b;c&&(b=b.parentNode);for(;!(a in b);)if(b=b.parentNode,!b)throw Error(a+" not found");d&&(b["_"+a+"Node"]=e);return{element:b,receive:function(c,d){var e;n.get(b,a,function(b){c(e=b)});void 0===e&&d&&n.get(d,a,function(b){void 0===e&&c(b)})},appendTo:c}},put:function(b,
c){c[a]=b}}}var t={"":0,"false":0,"true":1},u={display:["none",""],visibility:["hidden","visible"],"float":["none","left"]},k=m("div"),g=navigator.userAgent,q=-1<g.indexOf("WebKit")?"-webkit-":-1<g.indexOf("Firefox")?"-moz-":-1<g.indexOf("MSIE")?"-ms-":-1<g.indexOf("Opera")?"-o-":"",l;f=new f;f.root=!0;f.definitions={Math:Math,module:function(a,c){c||require([a]);return{then:function(b){require([a],b)}}},item:p("item"),content:p("content",function(a){a.appendChild(this.element)}),element:{forElement:function(a){return{element:a,
receive:function(c){c(a)},get:function(c){return this.element[c]}}}},event:{receive:function(a){a(l)}},each:{put:function(a,c){c.each=a}},prefix:{put:function(a,c,b){if("string"==typeof k.style[q+b])return c.setStyle(q+b,a),!0}},"var":{put:function(a,c,b){(c.variables||(c.variables={}))[b]=a;c=(c=c.variableListeners)&&c[b]||0;for(b=0;b<c.length;b++)c[b](a)},call:function(a,c,b,d){this.receive(function(a){a=d.toString().replace(/var\([^)]+\)/g,a);var f=t[a];if(-1<f){var g=u[b];g&&(a=g[f])}c.setStyle(b,
a)},c,a.args[0])},receive:function(a,c,b){var d=c;do{var e=d.variables&&d.variables[b]||d.definitions&&d.definitions[b];if(e){if(e.receive)return e.receive(a,c,b);c=d.variableListeners||(d.variableListeners={});(c[b]||(c[b]=[])).push(a);return a(e)}d=d.parent}while(d);a()}},"extends":{call:function(a,c){for(var b=a.args;0<b.length;)return h.extend(c,b[0],console.error)}},on:{put:function(a,c,b){r.on(document,b.slice(3),c.selector,function(d){l=d;var e=s(c,b,a);e.forElement&&(e=e.forElement(d.target));
e&&e.stop&&e.stop();l=null})}},"@supports":{selector:function(a){function c(b){var a;if(a=b.match(/^\s*not(.*)/))return!c(a[1]);if(a=b.match(/\((.*)\)/))return c(a[1]);if(a=b.match(/([^:]*):(.*)/))return b=h.convertCssNameToJs(a[1]),a=k.style[b]=a[2],k.style[b]==a;if(a=b.match(/\w+\[(.*)=(.*)\]/))return m(a[0])[a[1]]==a[2];if(a=b.match(/\w+/))return h.isTagSupported(a);throw Error("can't parse @supports string");}c(a.selector.slice(10))?a.selector="":a.disabled=!0}}};return f});
//# sourceMappingURL=base.js.map