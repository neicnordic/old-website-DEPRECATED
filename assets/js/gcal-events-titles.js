/*
Filter and render events from a Google calendar.
*/
function renderEventsTitles(mywidget, calendarid, key, past, hashtags, linkpref) {
var url = "https://www.googleapis.com/calendar/v3/calendars/" + calendarid + "/events?key=" + key + "&orderBy=startTime&singleEvents=true";
if (past) {
  url = url + "&timeMax=" + new Date().toISOString();
} else {
  url = url + "&timeMin=" + new Date().toISOString();
}

$.getJSON(url , function( data ) {
  var gettags = function (description) {
    var tags = [];
    var match;
    var regex = /(^|\s)#(\w[\w-]*)(?=\s|$)/g;
    while (match = regex.exec(description)) {
      tags.push(match[2].toLowerCase());
    }
    return tags;
  }
  var format_event = function (event) {
    var calendaricon = "https://wiki.neic.no/w/ext/img_auth.php/7/78/Calendar-icon.gif";
    var linkprefs = (linkprefs || 'wikipage,wiki,webpage,website,homepage,site,event,info,more info,more information,googlecalendar').split(",");
    var tags = hashtags.replace(/\s/g,'').toLowerCase().split(",");
    if (tags.length == 1 && tags[0] == '') {
      tags = [];
    }
    var urlregex = /(https?:\/\/\S+?)(\.?([\s\n]|$))/gi;
    var repl = '<span class="plainlinks"><a class="external text" rel="nofollow" href="$1">$1</a></span>$2'
    var summary = event.summary;
    var url = "";
    var calendarurl = event.htmlLink;
    var description = "";
    var ret = "";
    var description = event.description || "";
    var date = (event.start.date || event.start.dateTime).split('T')[0];
    var blurb = description.split('\n')[0].replace(urlregex, repl);
    // details
    var details = "";
    var descriptionmatch = description.match(/(.*(\n([\s\S]+))?)/m);
    if (descriptionmatch && descriptionmatch[3]) {
      details = descriptionmatch[3].replace(urlregex, repl).replace(/\n/g, '<br/>\n');
    }
    var tagged = false;
    if (tags.length > 0) {
      var eventtags = gettags(descriptionmatch[1]);
      for (var i in tags) {
        if (eventtags.indexOf(tags[i]) != -1) {
          tagged = true;
        }
      }
    }
    // url (uses descriptionmatch from above)
    for (var j in linkprefs) {
      var pref = linkprefs[j].trim();
      if (pref == "googlecalendar") {
        url = calendarurl;
      } else if (descriptionmatch) {
        var r = new RegExp('^\\s*' + pref + '\\s*:\\s*(https?:\\/\\/\\S+?)\\.?([\\s\\n]|$)', 'mi');
        match = descriptionmatch[1].match(r);
        if (match) {
          url = match[1];
        }
      }
      if (url) break;
    }  
    var ret = '<a href="' + calendarurl + '">' + date + '</a>: <a href="' + url + '">' + summary + '</a>';
    if (tagged) {
      ret = '<b>' + ret + '</b>';
    }
    return '<li>' + ret + '</li>';
  }
  var events = [];
  $.each(data.items, function (i, event) {
    events.push(format_event(event));
  })
  if (past) {
    events.reverse();
  }
  $("<ul/>", {html:events.join(""), class:"event-titles"}).appendTo(mywidget); 
});

};