/*
Filter and render events from a Google calendar.
*/
function renderEvents(mywidget, calendarid, key, past, hashtags, linkpref) {
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
    var enddate = (event.end.date || event.end.dateTime).split('T')[0];
    var d = new Date(enddate);
    d.setDate(d.getDate() - 1);
    if (d <= new Date(date)) {
      enddate = date;
    } else {
      enddate = d.toISOString().split('T')[0];
    }
    var blurb = description.split('\n')[0].replace(urlregex, repl);
    // details
    var details = "";
    var descriptionmatch = description.match(/(.*(\n([\s\S]+))?)/m);
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
      ret = ret + '<a href="' + url + '">' + summary + '</a> <a href="' + calendarurl + '"><img style="height: 12px; width: 12px; margin-left: 0.5em; vertical-align: text-top;" src="' + calendaricon + '"></a>';
    } else {
      ret = ret + summary;
    }
    if (enddate == date) {
      ret = ret  + '</b></dt><dd>' + date + '<br/>';
    } else {
      ret = ret  + '</b></dt><dd>' + date + ' &ndash; ' + enddate + '<br/>';
    }
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
  var events = [];
  $.each(data.items, function (i, event) {
    events.push(format_event(event));
  })
  if (past) {
    events.reverse();
  }
  $("<dl/>", {html:events.join("")}).appendTo(mywidget); 
});

$(document).ready(function() {
  $(mywidget).on("click", ".toggle", function() {
    $(this).closest(".detail").find(".hideable").toggle("fast");
  });
});
};
