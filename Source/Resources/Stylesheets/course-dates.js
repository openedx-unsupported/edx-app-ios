function filterHTML(classname, padding_left, padding_top, padding_right) {
    var text='';
    var divs = document.getElementsByClassName(classname);
    if (divs.length > 0)
    {
        for (i = 0; i< divs.length; i ++ ){
            text  += divs[i].outerHTML;
        }
        document.getElementsByTagName('body')[0].innerHTML = text;
        var style = document.createElement('style');
        style.innerHTML = 'body {padding-left: '+padding_left+'px; padding-top:'+padding_top+'px; padding-right:'+padding_right+'px}';
        document.head.appendChild(style);
        document.body.style.backgroundColor = 'white';
        document.getElementsByTagName('BODY')[0].style.minHeight = 'auto'
        
        return true
    }
    return false
}
filterHTML('%@', '%d', '%d', '%d');
