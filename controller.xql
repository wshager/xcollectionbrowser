xquery version "1.0";

declare namespace json="http://www.json.org";

import module namespace login-helper="http://exist-db.org/apps/dashboard/login-helper" at "/db/apps/dashboard/modules/login-helper.xql";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $login := login-helper:get-login-method();


if ($exist:resource = 'login' or starts-with($exist:path,"/auth")) then
    let $loggedIn := $login("org.exist.login",(), false())
    return
        try {
            util:declare-option("exist:serialize", "method=json"),
            if (request:get-attribute("org.exist.login.user")) then
                let $isAdmin := xmldb:is-admin-user(request:get-attribute("org.exist.login.user"))
                return
                <status>
                    <user>{request:get-attribute("org.exist.login.user")}</user>
                    <isAdmin json:literal="true">{$isAdmin}</isAdmin>
                    <role>{if($isAdmin) then "admin" else "user"}</role>
                </status>
            else (
                response:set-status-code(401),
                <status>fail</status>
            )
        } catch * {
            response:set-status-code(401),
            <status>{$err:description}</status>
        }
else if(starts-with($exist:path, "/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<forward url="{$exist:controller}/modules/service.xql">
            {$login("org.exist.login", (), false())}
            <set-header name="Cache-Control" value="no-cache"/>
            <add-parameter name="id" value="{$exist:path}"/>
		</forward>
	</dispatch>
else
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
