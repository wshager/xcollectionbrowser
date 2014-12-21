var list = {
	"dexist/dexist.profile" : 1,
	"dexist/package.json" : 1
};
var profile = {
	"releaseDir" : "release/dexist",
	"basePath" : "../",
	"action" : "release",
	"mini" : true,
	"stripConsole" : "all",
	"layerOptimize" : "closure",
	"cssOptimize" : "comments",
	"selectorEngine" : "lite",
	"defaultConfig" : {
		"hasCache" : {
			"dojo-built" : 1,
			"dojo-loader" : 1,
			"dom" : 1,
			"host-browser" : 1,
			"config-selectorEngine" : "lite"
		},
		"async" : 1
	},
	"staticHasFeatures" : {
		"config-deferredInstrumentation" : 0,
		"config-dojo-loader-catches" : 0,
		"config-tlmSiblingOfDojo" : 0,
		"dojo-amd-factory-scan" : 0,
		"dojo-combo-api" : 0,
		"dojo-config-api" : 1,
		"dojo-config-require" : 0,
		"dojo-debug-messages" : 0,
		"dojo-dom-ready-api" : 1,
		"dojo-firebug" : 0,
		"dojo-guarantee-console" : 1,
		"dojo-has-api" : 1,
		"dojo-inject-api" : 1,
		"dojo-loader" : 1,
		"dojo-log-api" : 0,
		"dojo-modulePaths" : 0,
		"dojo-moduleUrl" : 0,
		"dojo-publish-privates" : 0,
		"dojo-requirejs-api" : 0,
		"dojo-sniff" : 0,
		"dojo-sync-loader" : 0,
		"dojo-test-sniff" : 0,
		"dojo-timeout-api" : 0,
		"dojo-trace-api" : 0,
		"dojo-undef-api" : 0,
		"dojo-v1x-i18n-Api" : 1,
		"dom" : 1,
		"host-browser" : 1,
		"extend-dojo" : 1
	},
	"packages" : [ "dojo", "dijit", "dstore", "dgrid", "xstyle",
			"put-selector", "dforma", "dexist", "colorpicker" ],
	"resourceTags" : {
		"copyOnly" : function(filename, mid) {
			return (mid in list)
					|| (/(css|png|jpg|jpeg|gif|tiff)$/).test(filename);
		},
		"amd" : function(filename, mid) {
			return !(mid in list) && (/dexist/).test(mid)
					&& (/\.js$/).test(filename);
		}
	},
	"layers" : {
		"dexist/cb-layer" : {
			"include" : [ "dexist/CollectionBrowser"]
		}
	}
};