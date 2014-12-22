//>>built
define("xstyle/core/observe",[],function(){var c=function(a,b,e){var c="_listeners_"+b,d=a[c];if(!d){var f=a[b];Object.defineProperty(a,b,{get:function(){return f},set:function(a){f=a;for(var b=0,c=d.length;b<c;b++)d[b].call(this,a)}});d=a[c]=[]}d.push(e)};c.get=function(a,b,e){e(a[b]);return c(a,b,e)};return c});
//# sourceMappingURL=observe.js.map