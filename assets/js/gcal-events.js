/*
Filter and render events from a Google calendar.
*/
function renderEvents(mywidget, url, hashtags, linkpref) {
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
    linkpref = linkpref || "wikipage,wiki,webpage,website,homepage,site,event,info,more info,more information,googlecalendar";
    var calendaricon = "/assets/img/calendar-icon.gif";
    var linkprefs = linkpref.split(",");
    var tags = hashtags.replace(/\s/g,'').toLowerCase().split(",");
    if (tags.length == 1 && tags[0] == '') {
      tags = [];
    }
    var urlregex = /(https?:\/\/\S+?)(\.?([\s\n]|$))/gi;
    var repl = '<span class="plainlinks"><a class="external text" rel="nofollow" href="$1">$1</a></span>$2'
    var title = entry.title.$t;
    var url = "";
    var calendarurl = "";
    var description = "";
    var ret = "";
    var content = entry.content.$t.replace(/\\u003cbr \/\\u003e/g, '\n');
    var date = "";
    var blurb = "";
    var details = "";
    // calendarurl
    for (var i in entry.link) {
      if (entry.link[i].type == 'text/html' ) {
        calendarurl = entry.link[i].href;
      }
    }
    // date
    var match = content.match(/^When: (.+)/);
    if (match) {
      date = match[1];
    }
    // blurb
    match = content.match(/Event Description: (.+)/m);
    if (match) {
      blurb = match[1].replace(urlregex, repl);
    }
    // details
    var descriptionmatch = content.match(/Event Description: (.*(\n([\s\S]+))?)/m);
    if (descriptionmatch && descriptionmatch[3]) {
      details = descriptionmatch[3].replace(urlregex, repl).replace(/\n/g, '<br/>\n');
    }
    // return empty string if required tags not present, uses descriptionmatch from above
    if (tags.length > 0) {
      if (!descriptionmatch) {
        return '';
      }
      var eventtags = gettags(descriptionmatch[1]);
      for (var i in tags) {
        if (eventtags.indexOf(tags[i]) == -1) {
          return '';
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
    var ret = '<dt><b>';
    if (url) {
      ret = ret + '<a href="' + url + '">' + title + '</a> <a href="' + calendarurl + '"><img style="height: 12px; width: 12px; margin-left: 0.5em; vertical-align: text-top;" src="' + calendaricon + '"></a>';
    } else {
      ret = ret + title;
    }
    ret = ret  + '</b></dt><dd>' + date + '<br/>';
    if (blurb) {
      ret = ret + blurb + '<br/>';
    }
    if (details) {
      ret = ret + '<span class="detail">' + 
         '<span class="hideable" style="display:none;">' + details + '</span>' +
         '<div class="toggle" style="cursor:help"><a>Click to show/hide details</a></div>';
    }
    ret = ret + '</dd>';
    return ret;
  }
  var entries = [];
  $.each(data.feed.entry, function (i, entry) {
    entries.push(format_entry(entry));
  })
  $("<dl/>", {html:entries.join("")}).appendTo(mywidget); 
});

$(document).ready(function() {
  $(mywidget).on("click", ".toggle", function() {
    $(this).closest(".detail").find(".hideable").toggle("fast");
  });
});
};