//>>built
define("dforma/Group","dojo/_base/declare dojo/_base/array dojo/_base/lang ./_GroupMixin dijit/form/_FormValueWidget dijit/form/_FormMixin".split(" "),function(h,g,e,k,l,m){return h("dforma.Group",[l,k,m],{name:"",baseClass:"dformaGroup",value:null,_getValueAttr:function(){var d={};g.forEach(this._getDescendantFormWidgets(),function(b){var c=b.name;if(c&&!b.disabled){var a=b.get("value");"boolean"==typeof b.checked?/Radio/.test(b.declaredClass)?!1!==a?e.setObject(c,a,d):(a=e.getObject(c,!1,d),void 0===
a&&e.setObject(c,null,d)):e.setObject(c,"on"===a,d):(b=e.getObject(c,!1,d),"undefined"!=typeof b?e.isArray(b)?b.push(a):e.setObject(c,[b,a],d):e.setObject(c,a,d))}});return d},_setValueAttr:function(d){var b={};g.forEach(this._getDescendantFormWidgets(),function(a){a.name&&(b[a.name]||(b[a.name]=[])).push(a)});for(var c in b)if(b.hasOwnProperty(c)){var a=b[c],f=e.getObject(c,!1,d);void 0!==f&&(f=[].concat(f),"boolean"==typeof a[0].checked?g.forEach(a,function(a){a.set("value",-1!=g.indexOf(f,"on"===
a._get("value")))}):a[0].multiple?a[0].set("value",f):g.forEach(a,function(a,b){a.set("value",f[b])}))}}})});
//# sourceMappingURL=Group.js.map