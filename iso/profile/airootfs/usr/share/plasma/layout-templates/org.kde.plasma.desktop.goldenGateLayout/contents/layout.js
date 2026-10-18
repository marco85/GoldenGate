// GoldenGate OS — macOS 27 "Golden Gate" Plasma 6 Layout
// 1. Removes any default taskbar panels
// 2. Top Menu Bar (28px): Apple Launcher + Global Menu + Spacer + Auto-Collapsing Clutter Control System Tray + Clock
// 3. Bottom Floating Liquid Glass Dock (58px): Finder, Launchpad, Safari/Chrome, Antigravity, Claude, Codex, iCloud, Photos, AirDrop, Toolbox, Writer, Terminal, Liquid Glass, Settings, Trash

var existingPanels = panels();
for (var i = 0; i < existingPanels.length; i++) {
    existingPanels[i].remove();
}

var topBar = new Panel("org.kde.panel");
topBar.location = "top";
topBar.height = 28;
topBar.floating = false;
topBar.alignment = "center";
topBar.lengthMode = "fill";

var appleMenu = topBar.addWidget("org.kde.plasma.kickoff");
appleMenu.currentConfigGroup = ["General"];
appleMenu.writeConfig("icon", "start-here-kde");
appleMenu.writeConfig("menuButtons", "0123");

topBar.addWidget("org.kde.plasma.appmenu");
topBar.addWidget("org.kde.plasma.panelspacer");

// macOS 27 Golden Gate Menu Bar Clutter Control (auto-collapses overflow tray icons)
var sysTray = topBar.addWidget("org.kde.plasma.systemtray");
var sysTrayContainment = sysTray.readConfig("SystrayContainmentId");
if (sysTrayContainment) {
    var tray = desktopById(sysTrayContainment);
    if (tray) {
        tray.currentConfigGroup = ["General"];
        tray.writeConfig("iconSpacing", 1);
    }
}

var clock = topBar.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd MMM d");
clock.writeConfig("use24hFormat", 0);

// Bottom Floating Liquid Glass Dock
var dock = new Panel("org.kde.panel");
dock.location = "bottom";
dock.height = 58;
dock.floating = true;
dock.alignment = "center";
dock.lengthMode = "fit";
dock.hiding = "windowsgobelow";

var launchpad = dock.addWidget("org.kde.plasma.kickerdash");
launchpad.currentConfigGroup = ["General"];
launchpad.writeConfig("icon", "applications-all");

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "applications:google-chrome.desktop",
    "applications:antigravity.desktop",
    "applications:claude-desktop.desktop",
    "applications:chatgpt-codex.desktop",
    "applications:icloud-drive.desktop",
    "applications:icloud-photos.desktop",
    "applications:goldengate-airdrop.desktop",
    "applications:goldengate-toolbox.desktop",
    "applications:libreoffice-writer.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:goldengate-liquid-glass.desktop",
    "applications:goldengate-faceid.desktop",
    "applications:systemsettings.desktop"
]);
tasks.writeConfig("showOnlyCurrentDesktop", false);
tasks.writeConfig("groupingStrategy", 1);
tasks.writeConfig("iconSpacing", 1);

dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.trash");
