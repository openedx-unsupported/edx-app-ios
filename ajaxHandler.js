//Every time an Ajax call is being invoked the listener will recognize it and  will call the native app with the request details

$( document ).ajaxSuccess(function( event, request, settings )  {
    callNativeApp ({"status": request.status, "url":settings.url, "response_text":request.responseText});

});

function callNativeApp (data) {
    try {
        webkit.messageHandlers.ajaxCallbackHandler.postMessage(data);
    }
    catch(err) {
        console.log('The native context does not exist yet');
    }
}

/*
 <li id="openassessment__grade__block-v1:edX+Training101x+1T2018+type@openassessment+block@526eaceec9d54fdfa0b362c24f0f0be9" class="openassessment__steps__step step--grade is--showing  ui-slidable__container" tabindex="-1"><header class="step__header ui-slidable__control"><span><button class="ui-slidable" aria-expanded="false" id="oa_grade_block-v1:edX+Training101x+1T2018+type@openassessment+block@526eaceec9d54fdfa0b362c24f0f0be9" aria-controls="oa_grade_block-v1:edX+Training101x+1T2018+type@openassessment+block@526eaceec9d54fdfa0b362c24f0f0be9_content" aria-labeledby="oa_step_title_grade"><span class="icon fa fa-caret-right" aria-hidden="false"/></button></span><span><h4 class="step__title"><span class="wrapper--copy"><span id="oa_step_title_grade" class="step__label">Your Grade: </span><span class="grade__value"><span class="grade__value__title">Waiting for Assessments</span></span></span></h4></span></header><div class="ui-slidable__content" aria-labelledby="oa_grade_block-v1:edX+Training101x+1T2018+type@openassessment+block@526eaceec9d54fdfa0b362c24f0f0be9" id="oa_grade_block-v1:edX+Training101x+1T2018+type@openassessment+block@526eaceec9d54fdfa0b362c24f0f0be9_content"><div class="wrapper--step__content"><div class="step__content"><div class="step__message message message--waiting"><h5 class="message__title">Status</h5><div class="message__content">The grade for this problem is determined by the median score of your Peer Assessments.</div></div><div class="grade__value__description"><p>You have completed your steps in the assignment, but some assessments still need to be done on your response. When the assessments of your response are complete, you will see feedback from everyone who assessed your response, and you will receive your final grade.</p></div></div></div></div></li>
 */
