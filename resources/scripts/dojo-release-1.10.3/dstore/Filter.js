//>>built
define("dstore/Filter",["dojo/_base/declare"],function(e){function a(f){return function(){var b=this.constructor,c=new b;c.type=f;c.args=arguments;return this.type?a("and").call(b.prototype,this,c):c}}e=e(null,{constructor:function(a){var b=typeof a;switch(b){case "object":var b=this,c;for(c in a)var d=a[c],b=d instanceof this.constructor?b[d.type](c,d.args[0]):d&&d.test?b.match(c,d):b.eq(c,d);this.type=b.type;this.args=b.args;break;case "function":case "string":this.type=b,this.args=[a]}},and:a("and"),
or:a("or"),eq:a("eq"),ne:a("ne"),lt:a("lt"),lte:a("lte"),gt:a("gt"),gte:a("gte"),"in":a("in"),match:a("match")});e.filterCreator=a;return e});
//# sourceMappingURL=Filter.js.map