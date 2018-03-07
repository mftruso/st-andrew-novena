const fromObject = require("data/observable").fromObject;
var view = require("ui/core/view");
var frameModule = require("ui/frame");
var applicationSettings = require("application-settings");

var novenaPrayer = "Hail and blessed be the hour and moment in which the Son of God was born of the most pure Virgin Mary, at midnight, in Bethlehem, in piercing cold.\n\nIn that hour, vouchsafe, O my God! to hear my prayer and grant my desires, through the merits of Our Saviour Jesus Christ, and of His Blessed Mother."

var count = 0;
if (!applicationSettings.getNumber("prayerCount")) {
  applicationSettings.setNumber("prayerCount", 0);
} else {
  count = applicationSettings.getNumber("prayerCount");
}

function buttonTap(args) {
    count++;
    var sender = args.object;
    var parent = sender.parent;
    if (parent) {
        var lbl = view.getViewById(parent, "prayerCount");
        if (lbl) {
            lbl.text = count;
            applicationSettings.setNumber("prayerCount", count);
        }
    }
}
exports.buttonTap = buttonTap;

exports.pageLoaded = function (args) {
  const source = fromObject({
      novenaPrayer: novenaPrayer,
      prayerCount: count
  });
  const page = args.object;
  page.bindingContext = source;
}

exports.settings = function() {
    var topmost = frameModule.topmost();
    topmost.navigate("views/settings/settings");
};
