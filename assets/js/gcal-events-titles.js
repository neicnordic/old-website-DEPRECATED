/*
Filter and render events from a Google calendar.
*/
function renderEventsTitles(mywidget, url, hashtags, linkpref) {
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
  var format_entry = function (entry) {
    hashtags = hashtags || "";
    var tags = hashtags.replace(/\s/g,'').toLowerCase().split(",");
    if (tags.length == 1 && tags[0] == '') {
      tags = [];
    }
    linkpref = linkpref || "wikipage,wiki,webpage,website,homepage,site,event,info,more info,more information,googlecalendar";
    var linkprefs = linkpref.split(",");
    var title = entry.title.$t;
    var content = entry.content.$t.replace(/\\u003cbr \/\\u003e/g, '\n');
    var date = "";
    // date
    var match = content.match(/^When: (.+)/);
    if (match) {
      date = match[1].split(" ").slice(1,4).join(" ");
    }
    // check if all requested tags are present
    var tagged = false;
    var descriptionmatch = content.match(/Event Description: (.*(\n([\s\S]+))?)/m);
    if (tags.length > 0) {
      if (descriptionmatch) {
        var eventtags = gettags(descriptionmatch[1]);
        for (var i in tags) {
          if (eventtags.indexOf(tags[i]) != -1) {
            tagged = true;
            break;
          }
        }
      }
    }
    // calendarurl
    var calendarurl = "";
    for (var i in entry.link) {
      if (entry.link[i].type == 'text/html' ) {
        calendarurl = entry.link[i].href;
      }
    }
    // url (uses descriptionmatch from above)
    var eventurl = "";
    for (var j in linkprefs) {
      var pref = linkprefs[j].trim();
      if (pref == "googlecalendar") {
        eventurl = calendarurl;
      } else if (descriptionmatch) {
        var r = new RegExp('^\\s*' + pref + '\\s*:\\s*(https?:\\/\\/\\S+?)\\.?([\\s\\n]|$)', 'mi');
        match = descriptionmatch[1].match(r);
        if (match) {
          eventurl = match[1];
        }
      }
      if (eventurl) break;
    }  
    var ret = '<a href="' + calendarurl + '">' + date + '</a>: <a href="' + eventurl + '">' + title + '</a>';
    if (tagged) {
      ret = '<b>' + ret + '</b>';
    }
    return '<li>' + ret + '</li>';
  }
  var entries = [];
  $.each(data.feed.entry, function (i, entry) {
    entries.push(format_entry(entry));
  })
  $("<ul/>", {html:entries.join(""), class:"event-titles"}).appendTo(mywidget); 
});

};