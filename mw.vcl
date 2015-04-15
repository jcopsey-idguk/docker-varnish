#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and http://varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;

# Default backend definition. Set this to point to your content server.
#backend default {
#    .host = "192.168.208.43";
#    .port = "84";
#}

import directors;

backend web1 {
    .host = "192.168.208.43";
    .port = "84";
    .probe = {
                .url = "/";
                .interval = 5s;
                .timeout = 1s;
                .window = 5;
                .threshold = 3;
    }
    
}

backend web2 {
    .host = "192.168.208.44";
    .port = "84";
    .probe = {
                .url = "/";
                .interval = 5s;
                .timeout = 1s;
                .window = 5;
                .threshold = 3;
    }
}

backend web3 {
    .host = "192.168.208.46";
    .port = "84";
    .probe = {
                .url = "/";
                .interval = 5s;
                .timeout = 1s;
                .window = 5;
                .threshold = 3;
    }
}

backend web4 {
    .host = "192.168.208.32";
    .port = "84";
    .probe = {
                .url = "/";
                .interval = 5s;
                .timeout = 1s;
                .window = 5;
                .threshold = 3;
    }
}

sub vcl_init {
    new bar = directors.round_robin();
    bar.add_backend(web1);
    bar.add_backend(web2);
    bar.add_backend(web3);
    bar.add_backend(web4);
}

#director macworld round-robin {
#    {
#	.backend = web1;
#    }
#    {
#        .backend = web2;
#    }
#    {
#        .backend = web3;
#    }
#    {
#        .backend = web4;
#    }
#}

# Who is allowed to purge....
acl local {
    "localhost";
    "192.168.3.0"/24; /* and everyone on the local network */
}

sub vcl_recv {
    # Happens before we check if we have this in cache already.
    # 
    # Typically you clean up the request here, removing cookies you don't need,
    # rewriting the request, etc.
    
    #if (req.http.host ~ "^(www.)?macworld.co.uk$") {
	#set req.backend = macworld;
    #}

    set req.backend_hint = bar.backend();

    if (req.method == "PURGE") {
      if (client.ip ~ local) {
         return(purge);
      } else {
         return(synth(403, "Access denied."));
      }
    }
    if(req.http.Cookie) {
	set req.http.X-Cookie = req.http.Cookie;
        unset req.http.Cookie;
    }
    
    # Only cache GET or HEAD requests. This makes sure the POST requests are always passed.
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }
}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    # 
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.

    if (beresp.http.cache-control ~ "(no-cache|private)" ||
            beresp.http.pragma ~ "no-cache") {

	#set beresp.uncacheable = true;
	set beresp.ttl = 0s;
	set beresp.http.X-Cacheable = "NO:Cache-Control=nocache";
	return (deliver);
  
    } elseif (bereq.http.Cookie ~ "(somecookie|_session)") {
        set beresp.http.X-Cacheable = "NO:Got Session";
        set beresp.uncacheable = true;
        return (deliver);

    } elsif (beresp.http.set-cookie) {
        # You don't wish to cache content for logged in users
        set beresp.http.X-Cacheable = "NO:Set-Cookie";
        set beresp.uncacheable = true;
        return (deliver);

    } elsif (beresp.http.Cache-Control ~ "private") {
        # You are respecting the Cache-Control=private header from the backend
        set beresp.http.X-Cacheable = "NO:Cache-Control=private";
        set beresp.uncacheable = true;
        return (deliver);

    } elsif (beresp.ttl <= 0s) {
        # Varnish determined the object was not cacheable
        set beresp.http.X-Cacheable = "NO:Not Cacheable";

    } else {
        # Varnish determined the object was cacheable
        set beresp.http.X-Cacheable = "YES";
    }
    return(deliver);
}

sub vcl_miss {
    if(req.http.X-Cookie){
	set req.http.Cookie = req.http.X-Cookie;
	unset req.http.X-Cookie;
    }
}

sub vcl_pass {
    if(req.http.X-Cookie){
        set req.http.Cookie = req.http.X-Cookie;
        unset req.http.X-Cookie;
    }
}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    # 
    # You can do accounting or modifying the final object here.
	if (obj.hits > 0) {
                set resp.http.X-Cache = "HIT";
        } else {
                set resp.http.X-Cache = "MISS";
        }
   if(resp.http.Server){ 
       unset resp.http.Server;
   }
   if(resp.http.X-Powered-By){
       unset resp.http.X-Powered-By;
   }
}


