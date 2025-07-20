import i18n from 'utils/i18n'

Date.months = i18n.t('date.month_names').filter(n => n);
Date.weekdays = i18n.t('calendar.abbr_weekdays');
Date.firstDayOfWeek = "sunday";

Number.prototype.toPaddedString = function toPaddedString(length, radix) {
  var string = this.toString(radix || 10);
  return '0'.repeat(length - string.length) + string;
}

Date.prototype.beginning_of_day = function () {
  var date = new Date(this);
  date.setHours(0);
  date.setMinutes(0);
  date.setSeconds(0);
  date.setMilliseconds(0);
  return date;
},

Date.prototype.beginning_of_next_day = function () {
  var date = this.add_days(1)
  date.setHours(0)
  date.setMinutes(0)
  date.setSeconds(0)
  date.setMilliseconds(0)
  return date
},

Date.prototype.add_days = function (interval) {
  var date = new Date(this)
  date.setDate(this.getDate() + interval)
  return date
},

Date.prototype.add_weeks = function (interval) {
  return this.add_days(interval * 7)
},

Date.prototype.add_months = function (interval) {
  var date = new Date(this)
  date.setMonth(this.getMonth() + interval)
  return date
},

Date.prototype.is_today = function () {
  var now = new Date()
  var today = now.beginning_of_day()
  var tomorrow = new Date(today).add_days(1)
  return (this >= today && this < tomorrow)
},

Date.prototype.is_tomorrow = function () {
  var now = new Date()
  var tomorrow = now.beginning_of_day().add_days(1)
  var day_after = new Date(tomorrow).add_days(1)
  return (this >= tomorrow && this < day_after)
},

Date.prototype.is_within = function (other_date) {
  var now = (new Date()).beginning_of_day()
  var extent = new Date(other_date).beginning_of_day()
  return (this >= now && this < extent)
},

Date.prototype.days_since = function () {
  return Math.round(((new Date()).beginning_of_day() - this.beginning_of_day()) / 86400000.0)
},

// Renders date with custom formatting, similar to Ruby's strftime
Date.prototype.strftime = function (format) {
  var minutes = this.getMinutes(),
    hours = this.getHours(),
    day = this.getDay(),
    month = this.getMonth();

  function pad(num) { return num.toPaddedString(2); }

  return format.replace(/\%([aAbBcdDHiImMpSwyY])/g, function (part) {
    switch (part[1]) {
      case 'a': return i18n.t('date.abbr_day_names')[day];
      case 'A': return i18n.t('date.day_names')[day];
      case 'b': return i18n.t('date.abbr_month_names')[month + 1];
      case 'B': return i18n.t('date.month_names')[month + 1];
      case 'c': return this.strftime("%a %b %d %H:%M:%S %Y");
      case 'd': return this.getDate();
      case 'D': return pad(this.getDate());
      case 'H': return pad(hours);
      case 'i': return (hours === 12 || hours === 0) ? 12 : (hours + 12) % 12;
      case 'I': return pad((hours === 12 || hours === 0) ? 12 : (hours + 12) % 12);
      case 'm': return pad(month + 1);
      case 'M': return pad(minutes);
      case 'p': return hours > 11 ? i18n.t('time.pm') : i18n.t('time.am');
      case 'S': return pad(this.getSeconds());
      case 'w': return day;
      case 'y': return pad(this.getFullYear() % 100);
      case 'Y': return this.getFullYear().toString();
    }
  }.bind(this));
}

// Will parse date and give its relative distance in words to
// current_date (which defaults to now)
Date.prototype.timeAgo = function (current_date) {
  current_date = current_date || new Date();

  var posted_date = new Date(this);
  var elapsed = current_date - posted_date;

  var minutes = Math.floor(elapsed / (1000 * 60));
  var days = Math.floor(elapsed / (1000 * 60 * 60 * 24));
  var today = (current_date.getDay() === posted_date.getDay() && days < 2);

  if (elapsed < 0) {
    return posted_date.strftime(i18n.t('date.formats.long'));
  }
  else if (minutes === 0) {
    return i18n.t('datetime.distance_in_words.now');
  }
  else if (minutes == 1) {
    return i18n.t('datetime.time_ago', { time_ago_in_words: i18n.t('datetime.distance_in_words.x_minutes.one') });
  }
  else if (minutes < 60) {
    return i18n.t('datetime.time_ago', { time_ago_in_words: i18n.t('datetime.distance_in_words.x_minutes.other', { count: minutes }) });
  }
  else if (today) {
    return posted_date.strftime(i18n.t('time.formats.short'));
  }
  else if (days == 1) {
    return i18n.t('date.yesterday') + ' ' + posted_date.strftime(i18n.t('time.formats.short'));
  }
  else if (days <= 14) {
    return posted_date.strftime("%a " + i18n.t('date.formats.short'));
  }
  else if (current_date.getFullYear() == posted_date.getFullYear()) {
    return posted_date.strftime(i18n.t('date.formats.short'));
  }
  else { return posted_date.strftime(i18n.t('date.formats.long')); }
}
