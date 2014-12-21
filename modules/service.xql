xquery version "3.0";

import module namespace sm="http://exist-db.org/xquery/securitymanager";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace service="http://exist-db.org/apps/collectionbrowser/service" at "service.xqm";

declare namespace json="http://www.json.org";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "json";
declare option output:media-type "application/json";

let $collection := request:get-parameter("collection","")
let $id := request:get-parameter("id","")
let $method := request:get-method()
let $data := request:get-data()
let $id := 
    if($id eq "/") then
        ""
    else
        $id
return 
    if($method eq "GET")  then
        if($id ne "" or $collection ne "") then
            service:resources($id,$collection)
        else
            ()
    else
        ()