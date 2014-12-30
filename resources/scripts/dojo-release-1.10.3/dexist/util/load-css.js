//>>built
define("dexist/util/load-css",["dojo/query"],function(e){return function(c,b){b=b||document;var d=b.getElementsByTagName("head")[0];e("link",d).some(function(a){return a.getAttribute("href")===c});var a=document.createElement("link");a.setAttribute("rel","stylesheet");a.setAttribute("type","text/css");a.setAttribute("href",c);d.appendChild(a)}});
//# sourceMappingURL=load-css.js.map