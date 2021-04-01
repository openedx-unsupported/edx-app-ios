//Every time an Ajax call is being invoked the listener will recognize it and  will call the native app with the request details

$(document).ajaxSuccess(function(event, request, settings)  {
    callNativeApp({
        "status": request.status,
        "url":settings.url,
        "response_text": request.responseText
    });
});

function callNativeApp(data) {
    try {
        webkit.messageHandlers.ajaxCallbackHandler.postMessage(data);
    }
    catch(err) {
        console.log('The native context does not exist yet');
    }
}
