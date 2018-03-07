var observableModule = require("data/observable");
const fromObject = observableModule.fromObject;
var applicationSettings = require("application-settings");
var dialogs = require("ui/dialogs")
var LocalNotifications = require("nativescript-local-notifications");


exports.pageLoaded = function (args) {
  const source = fromObject({
      notificationsEnabled: applicationSettings.getBoolean("notificationsEnabled")
  });
  const page = args.object;
  page.bindingContext = source;
}

function toggleNotifications(args) {
  const sw = args.object;
  sw.on("checkedChange", (args) => {
     applicationSettings.setBoolean("notificationsEnabled", sw.checked)

     if(sw.checked) {
       scheduleNotifications();
     } else {
       cancelNotifications();
     }
  })
}
exports.toggleNotifications = toggleNotifications;

function scheduleNotifications() {
  LocalNotifications.schedule([{
      id: 1,
      title: 'Pray the St. Andrew Novena',
      body: 'Oremus',
      bigTextStyle: true, // Adds an 'expansion arrow' to the notification (Android only)
      at: new Date(new Date().getTime() + (10*1000)), // 10 seconds from now
      interval: 'minute'
    }]).then(
        function() {
          dialogs.alert({
            title: "Notifications scheduled",
            message: "Reminders will appear once an hour until you've reached 15 recitations",
            okButtonText: "OK, thanks"
          });
        },
        function(error) {
          console.log("doSchedule error: " + error);
        }
    );
}

function cancelNotifications() {
  LocalNotifications.cancelAll().then(
        function() {
          dialogs.alert({
            title: "All canceled",
            okButtonText: "Awesome!"
          });
        },
        function(error) {
          console.log("doCancelAll error: " + error);
        }
    );
}
