xquery version "3.0";

declare namespace json="http://www.json.org";

import module namespace rst="http://lagua.nl/lib/rst" at "modules/util/rst.xql";
import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace config="http://exist-db.org/apps/collectionbrowser/config" at "modules/config.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;


if ($exist:resource = 'login') then
    let $loggedIn := login:set-user("org.exist.login", (), false())
    return
        try {
            util:declare-option("exist:serialize", "method=json"),
            if (request:get-attribute("org.exist.login.user")) then
                let $isAdmin := xmldb:is-admin-user(request:get-attribute("org.exist.login.user"))
                return
                <status>
                    <user>{request:get-attribute("org.exist.login.user")}</user>
                    <isAdmin json:literal="true">{$isAdmin}</isAdmin>
                </status>
            else (
                response:set-status-code(401),
                <status>fail</status>
            )
        } catch * {
            response:set-status-code(401),
            <status>{$err:description}</status>
        }
else if(starts-with($exist:path, "/db")) then
    let $seq := subsequence(tokenize($exist:path,"/"), 2)
    let $path := string-join($seq,"/")
    let $loggedIn := login:set-user("org.exist.login", (), false())
    (: import params from config :)
    
    return rst:process($exist:path,map {
		"module-uri" := "http://exist-db.org/apps/collectionbrowser/service",
		"module-prefix" := "service",
		"module-location" := $config:app-root || "/modules/service.xql"
	}, map {
        "collection" := request:get-parameter("collection","/db"),
        "range" := request:get-header("range")
    })
else if(starts-with($exist:path, "/user")) then
    let $seq := subsequence(tokenize($exist:path,"/"), 2)
    let $path := string-join($seq,"/")
    let $loggedIn := login:set-user("org.exist.login", (), false())
    (: import params from config :)
    
    return rst:process($exist:path,map {
		"module-uri" := "http://exist-db.org/apps/collectionbrowser/user",
		"module-prefix" := "user",
		"module-location" := $config:app-root || "/modules/user.xql"
	}, map {
        "range" := request:get-header("range")
    })
else
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
